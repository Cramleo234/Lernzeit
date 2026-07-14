import AppKit
import CoreGraphics
import Foundation
import SwiftData
import SwiftUI
import UserNotifications

enum TimerMode: String, CaseIterable, Identifiable {
    case stopwatch
    case countdown
    case pomodoro

    var id: String { rawValue }
    var label: String {
        switch self {
        case .stopwatch: localized("timer.mode.stopwatch")
        case .countdown: localized("timer.mode.countdown")
        case .pomodoro: localized("timer.mode.pomodoro")
        }
    }
}

enum PomodoroPhase: String, Codable, Equatable {
    case focus
    case shortBreak
    case longBreak

    var isBreak: Bool { self != .focus }

    var label: String {
        switch self {
        case .focus:
            localized("timer.phase.focus")
        case .shortBreak:
            localized("timer.phase.break")
        case .longBreak:
            localized("timer.phase.long_break")
        }
    }
}

enum SettingsKeys {
    static let focusMinutes = "focusMinutes"
    static let breakMinutes = "breakMinutes"
    static let longBreakMinutes = "longBreakMinutes"
    static let roundsPerCycle = "roundsPerCycle"
    static let autoStartNextPhase = "autoStartNextPhase"
    static let customTimerMinutes = "customTimerMinutes"
    static let dailyGoalMinutes = "dailyGoalMinutes"
    static let appAppearance = "appAppearance"
    static let soundsEnabled = "soundsEnabled"
    static let notchLineEnabled = "notchLineEnabled"
    static let autoPauseOnLock = "autoPauseOnLock"
    static let autoPauseIdleMinutes = "autoPauseIdleMinutes"
}

@MainActor
@Observable
final class TimerEngine {
    var mode: TimerMode = .stopwatch
    var isRunning = false
    var isPaused = false
    var isAutoPaused = false
    var selectedSubject: Subject?
    private(set) var activePresetName = ""

    private var pomodoroCycle = PomodoroCycle()
    private var presetPlan: PomodoroPlan?
    private var presetCountdownMinutes: Int?
    private var phaseExtraDuration: TimeInterval = 0

    var phase: PomodoroPhase { pomodoroCycle.phase }
    var completedPomodoros: Int { pomodoroCycle.completedFocusRounds }

    private(set) var now: Date = .now

    private var timer: Timer?
    private var sessionStart: Date?
    private var phaseStart: Date = .now
    private var phaseAccumulated: TimeInterval = 0
    private var focusAccumulated: TimeInterval = 0
    private var pausedByLock = false
    private var todayBaseSeconds: TimeInterval = 0
    private var modelContext: ModelContext?
    private let notchOverlay = NotchOverlayController()
    private let soundPlayer = TimerSoundPlayer()

    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKeys.soundsEnabled: true,
            SettingsKeys.notchLineEnabled: true,
            SettingsKeys.autoPauseOnLock: true,
            SettingsKeys.autoPauseIdleMinutes: 3,
            SettingsKeys.longBreakMinutes: 20,
            SettingsKeys.roundsPerCycle: 4,
            SettingsKeys.autoStartNextPhase: true,
        ])
        observeLockState()
    }

    func configure(context: ModelContext) {
        modelContext = context
        if UserDefaults.lernzeitShared.object(forKey: SettingsKeys.dailyGoalMinutes) == nil {
            let legacy = UserDefaults.standard.integer(forKey: SettingsKeys.dailyGoalMinutes)
            UserDefaults.lernzeitShared.set(legacy > 0 ? legacy : 120, forKey: SettingsKeys.dailyGoalMinutes)
        }
    }

    // MARK: - Abgeleitete Werte

    var pomodoroPlan: PomodoroPlan {
        if let presetPlan { return presetPlan }
        let focus = UserDefaults.standard.integer(forKey: SettingsKeys.focusMinutes)
        let shortBreak = UserDefaults.standard.integer(forKey: SettingsKeys.breakMinutes)
        let longBreak = UserDefaults.standard.integer(forKey: SettingsKeys.longBreakMinutes)
        let rounds = UserDefaults.standard.integer(forKey: SettingsKeys.roundsPerCycle)
        return PomodoroPlan(
            focusMinutes: focus > 0 ? focus : 25,
            shortBreakMinutes: shortBreak > 0 ? shortBreak : 5,
            longBreakMinutes: longBreak > 0 ? longBreak : 20,
            roundsPerCycle: rounds > 0 ? rounds : 4,
            autoStartNextPhase: UserDefaults.standard.bool(forKey: SettingsKeys.autoStartNextPhase)
        )
    }

    var focusDuration: TimeInterval { TimeInterval(pomodoroPlan.focusMinutes * 60) }
    var breakDuration: TimeInterval { TimeInterval(pomodoroPlan.shortBreakMinutes * 60) }
    var longBreakDuration: TimeInterval { TimeInterval(pomodoroPlan.longBreakMinutes * 60) }

    var customTimerDuration: TimeInterval {
        if let presetCountdownMinutes { return TimeInterval(presetCountdownMinutes * 60) }
        let minutes = UserDefaults.standard.integer(forKey: SettingsKeys.customTimerMinutes)
        return TimeInterval(minutes > 0 ? minutes : 25) * 60
    }

    var goalMinutes: Int {
        let value = UserDefaults.lernzeitShared.integer(forKey: SettingsKeys.dailyGoalMinutes)
        return value > 0 ? value : 120
    }

    var currentPhaseDuration: TimeInterval {
        if mode == .countdown { return customTimerDuration }
        let base = pomodoroCycle.duration(using: pomodoroPlan)
        return base + (phase.isBreak ? phaseExtraDuration : 0)
    }

    var roundInCycle: Int {
        let rounds = max(1, pomodoroPlan.roundsPerCycle)
        if phase == .focus { return (completedPomodoros % rounds) + 1 }
        return ((max(1, completedPomodoros) - 1) % rounds) + 1
    }

    var phaseElapsed: TimeInterval {
        guard isRunning else { return 0 }
        if isPaused { return phaseAccumulated }
        return phaseAccumulated + now.timeIntervalSince(phaseStart)
    }

    var displayTime: TimeInterval {
        switch mode {
        case .stopwatch:
            return phaseElapsed
        case .countdown, .pomodoro:
            return max(0, currentPhaseDuration - phaseElapsed)
        }
    }

    var displayString: String {
        clockString(displayTime, alwaysShowHours: mode == .stopwatch)
    }

    var phaseProgress: Double {
        guard mode != .stopwatch, currentPhaseDuration > 0 else { return 0 }
        return min(1, phaseElapsed / currentPhaseDuration)
    }

    /// Reine Lernzeit der laufenden Session (Pomodoro-Pausen zählen nicht mit).
    var totalFocusTime: TimeInterval {
        switch mode {
        case .stopwatch:
            return phaseElapsed
        case .countdown:
            return min(phaseElapsed, customTimerDuration)
        case .pomodoro:
            return focusAccumulated + (phase == .focus ? min(phaseElapsed, focusDuration) : 0)
        }
    }

    /// Fortschritt für Notch-Linie und Menüleisten-Ring:
    /// Pomodoro und Timer zeigen die laufende Phase, die Stoppuhr den Weg zum Tagesziel.
    var ambientProgress: Double {
        if mode != .stopwatch { return phaseProgress }
        let goal = Double(goalMinutes) * 60
        guard goal > 0 else { return 0 }
        return min(1, (todayBaseSeconds + totalFocusTime) / goal)
    }

    var ambientColor: Color {
        if mode == .pomodoro && phase.isBreak { return .green }
        return selectedSubject?.color ?? .accentColor
    }

    // MARK: - Steuerung

    func apply(_ preset: TimerPreset) {
        guard !isRunning else { return }
        mode = preset.mode
        selectedSubject = preset.subject
        activePresetName = preset.name
        presetPlan = preset.mode == .pomodoro ? preset.pomodoroPlan : nil
        presetCountdownMinutes = preset.mode == .countdown ? preset.countdownMinutes : nil
        pomodoroCycle.reset()
        phaseExtraDuration = 0
    }

    func clearPresetConfiguration() {
        guard !isRunning else { return }
        activePresetName = ""
        presetPlan = nil
        presetCountdownMinutes = nil
        pomodoroCycle.reset()
        phaseExtraDuration = 0
    }

    func start() {
        guard !isRunning else { return }
        sessionStart = .now
        phaseStart = .now
        phaseAccumulated = 0
        focusAccumulated = 0
        pomodoroCycle.reset()
        phaseExtraDuration = 0
        isRunning = true
        isPaused = false
        isAutoPaused = false
        pausedByLock = false
        todayBaseSeconds = fetchTodayTotal()
        startTimer()
        syncAmbient()
        if mode != .stopwatch { requestNotificationPermission() }
    }

    func pause(auto: Bool = false) {
        guard isRunning, !isPaused else { return }
        phaseAccumulated += Date.now.timeIntervalSince(phaseStart)
        isPaused = true
        isAutoPaused = auto
    }

    func resume() {
        guard isRunning, isPaused else { return }
        phaseStart = .now
        isPaused = false
        isAutoPaused = false
        pausedByLock = false
    }

    @discardableResult
    func stop() -> StudySession? {
        guard isRunning, let sessionStart else { return nil }
        if !isPaused {
            phaseAccumulated += Date.now.timeIntervalSince(phaseStart)
            isPaused = true
        }
        let focusTime: TimeInterval
        if mode == .stopwatch {
            focusTime = phaseAccumulated
        } else if mode == .countdown {
            focusTime = min(phaseAccumulated, customTimerDuration)
        } else {
            focusTime = focusAccumulated + (phase == .focus ? min(phaseAccumulated, focusDuration) : 0)
        }

        var saved: StudySession?
        if focusTime >= 5 {
            saved = saveSession(startDate: sessionStart, duration: focusTime)
            if saved != nil {
                celebrateIfGoalReached(sessionSeconds: focusTime)
            }
        }
        reset()
        return saved
    }

    @discardableResult
    private func saveSession(startDate: Date, duration: TimeInterval) -> StudySession? {
        guard let modelContext else { return nil }
        let session = StudySession(
            startDate: startDate,
            endDate: .now,
            duration: duration,
            modeRaw: mode.rawValue,
            subject: selectedSubject,
            presetName: activePresetName,
            completedFocusRounds: completedPomodoros
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
            return session
        } catch {
            modelContext.delete(session)
            return nil
        }
    }

    private func reset() {
        isRunning = false
        isPaused = false
        isAutoPaused = false
        pausedByLock = false
        pomodoroCycle.reset()
        phaseExtraDuration = 0
        phaseAccumulated = 0
        focusAccumulated = 0
        sessionStart = nil
        stopTimer()
        syncAmbient()
    }

    // MARK: - Timer-Tick

    private func startTimer() {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        now = .now
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        now = .now
        syncAmbient()
        guard isRunning else { return }

        if isPaused {
            if isAutoPaused && !pausedByLock && currentIdleSeconds() < 2 {
                resume()
            }
            return
        }

        let idleLimitMinutes = UserDefaults.standard.integer(forKey: SettingsKeys.autoPauseIdleMinutes)
        let idleLimit = Double(idleLimitMinutes * 60)
        let checksIdle = mode != .pomodoro || phase == .focus
        if checksIdle, idleLimitMinutes > 0, phaseElapsed >= idleLimit, currentIdleSeconds() >= idleLimit {
            pause(auto: true)
            return
        }

        if mode == .countdown, phaseElapsed >= customTimerDuration {
            finishCountdown()
            return
        }

        if mode == .pomodoro, phaseElapsed >= currentPhaseDuration {
            advancePhase()
        }
    }

    private func finishCountdown() {
        guard let sessionStart else { return }
        phaseAccumulated = customTimerDuration
        let duration = customTimerDuration
        let saved = saveSession(startDate: sessionStart, duration: duration)
        if saved != nil {
            celebrateIfGoalReached(sessionSeconds: duration)
        }
        playSound(for: .countdownFinished)
        notify(
            title: localized("notification.timer_complete_title"),
            body: localized("notification.timer_complete_body")
        )
        reset()
    }

    private func advancePhase() {
        let completedPhase = phase
        if completedPhase == .focus {
            focusAccumulated += focusDuration
        }
        let nextPhase = pomodoroCycle.completeCurrentPhase(using: pomodoroPlan)
        phaseExtraDuration = 0
        phaseStart = .now
        phaseAccumulated = 0

        if completedPhase == .focus {
            playSound(for: .focusFinished)
            let minutes = Int(pomodoroCycle.duration(using: pomodoroPlan) / 60)
            notify(
                title: localized("notification.focus_complete_title"),
                body: localized("notification.break_time_body", minutes)
            )
        } else {
            playSound(for: .breakFinished)
            notify(
                title: localized("notification.break_over_title"),
                body: localized("notification.break_over_body")
            )
        }

        if !pomodoroPlan.autoStartNextPhase {
            isPaused = true
            isAutoPaused = false
        } else if nextPhase == .focus {
            isPaused = false
        }
    }

    func skipBreak() {
        guard isRunning, mode == .pomodoro, phase.isBreak else { return }
        advancePhase()
    }

    func extendBreak(byMinutes minutes: Int = 5) {
        guard isRunning, mode == .pomodoro, phase.isBreak else { return }
        phaseExtraDuration += TimeInterval(max(1, minutes) * 60)
    }

    // MARK: - Automatische Pause

    private func observeLockState() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.screenLocked() }
        }
        center.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.screenUnlocked() }
        }
    }

    private func screenLocked() {
        guard isRunning, !isPaused,
              UserDefaults.standard.bool(forKey: SettingsKeys.autoPauseOnLock) else { return }
        pause(auto: true)
        pausedByLock = true
    }

    private func screenUnlocked() {
        if pausedByLock { resume() }
    }

    private func currentIdleSeconds() -> Double {
        let types: [CGEventType] = [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown, .scrollWheel]
        return types
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0
    }

    // MARK: - Ambient

    private func syncAmbient() {
        let notchEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.notchLineEnabled)
        if isRunning && notchEnabled {
            notchOverlay.show(engine: self)
        } else {
            notchOverlay.hide()
        }
    }

    // MARK: - Ziel & Feedback

    private func fetchTodayTotal() -> TimeInterval {
        guard let modelContext else { return 0 }
        let dayStart = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { $0.startDate >= dayStart }
        )
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        return sessions.reduce(0) { $0 + $1.duration }
    }

    private func celebrateIfGoalReached(sessionSeconds: TimeInterval) {
        let goal = TimeInterval(goalMinutes) * 60
        let before = todayBaseSeconds
        let after = before + sessionSeconds
        guard before < goal, after >= goal else { return }
        playSound(for: .goalReached)
        notify(
            title: localized("notification.daily_goal_title"),
            body: localized("notification.daily_goal_body", formatDuration(after))
        )
    }

    private func playSound(for event: TimerSoundEvent) {
        soundPlayer.play(event.cue)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
