import AppKit
import CoreGraphics
import Foundation
import SwiftData
import SwiftUI
import UserNotifications

enum TimerMode: String, CaseIterable, Identifiable {
    case stopwatch
    case pomodoro

    var id: String { rawValue }
    var label: String { self == .stopwatch ? "Stoppuhr" : "Pomodoro" }
}

enum PomodoroPhase {
    case focus
    case pause

    var label: String { self == .focus ? "Fokus" : "Pause" }
}

enum SettingsKeys {
    static let focusMinutes = "focusMinutes"
    static let breakMinutes = "breakMinutes"
    static let dailyGoalMinutes = "dailyGoalMinutes"
    static let appAppearance = "appAppearance"
    static let soundsEnabled = "soundsEnabled"
    static let dockBadgeEnabled = "dockBadgeEnabled"
    static let notchLineEnabled = "notchLineEnabled"
    static let autoPauseOnLock = "autoPauseOnLock"
    static let autoPauseIdleMinutes = "autoPauseIdleMinutes"
}

@MainActor
@Observable
final class TimerEngine {
    var mode: TimerMode = .stopwatch
    var phase: PomodoroPhase = .focus
    var isRunning = false
    var isPaused = false
    var isAutoPaused = false
    var completedPomodoros = 0
    var selectedSubject: Subject?

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

    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKeys.soundsEnabled: true,
            SettingsKeys.dockBadgeEnabled: true,
            SettingsKeys.notchLineEnabled: true,
            SettingsKeys.autoPauseOnLock: true,
            SettingsKeys.autoPauseIdleMinutes: 3,
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

    var focusDuration: TimeInterval {
        let minutes = UserDefaults.standard.integer(forKey: SettingsKeys.focusMinutes)
        return TimeInterval(minutes > 0 ? minutes : 25) * 60
    }

    var breakDuration: TimeInterval {
        let minutes = UserDefaults.standard.integer(forKey: SettingsKeys.breakMinutes)
        return TimeInterval(minutes > 0 ? minutes : 5) * 60
    }

    var goalMinutes: Int {
        let value = UserDefaults.lernzeitShared.integer(forKey: SettingsKeys.dailyGoalMinutes)
        return value > 0 ? value : 120
    }

    var currentPhaseDuration: TimeInterval {
        phase == .focus ? focusDuration : breakDuration
    }

    var phaseElapsed: TimeInterval {
        guard isRunning else { return 0 }
        if isPaused { return phaseAccumulated }
        return phaseAccumulated + now.timeIntervalSince(phaseStart)
    }

    var displayTime: TimeInterval {
        mode == .pomodoro ? max(0, currentPhaseDuration - phaseElapsed) : phaseElapsed
    }

    var displayString: String {
        clockString(displayTime, alwaysShowHours: mode == .stopwatch)
    }

    var phaseProgress: Double {
        guard mode == .pomodoro, currentPhaseDuration > 0 else { return 0 }
        return min(1, phaseElapsed / currentPhaseDuration)
    }

    /// Reine Lernzeit der laufenden Session (Pomodoro-Pausen zählen nicht mit).
    var totalFocusTime: TimeInterval {
        if mode == .stopwatch { return phaseElapsed }
        return focusAccumulated + (phase == .focus ? min(phaseElapsed, focusDuration) : 0)
    }

    /// Fortschritt für Notch-Linie, Menüleisten-Ring und Dock:
    /// Pomodoro zeigt die laufende Phase, die Stoppuhr den Weg zum Tagesziel.
    var ambientProgress: Double {
        if mode == .pomodoro { return phaseProgress }
        let goal = Double(goalMinutes) * 60
        guard goal > 0 else { return 0 }
        return min(1, (todayBaseSeconds + totalFocusTime) / goal)
    }

    var ambientColor: Color {
        if mode == .pomodoro && phase == .pause { return .green }
        return selectedSubject?.color ?? .accentColor
    }

    // MARK: - Steuerung

    func start() {
        guard !isRunning else { return }
        sessionStart = .now
        phaseStart = .now
        phaseAccumulated = 0
        focusAccumulated = 0
        completedPomodoros = 0
        phase = .focus
        isRunning = true
        isPaused = false
        isAutoPaused = false
        pausedByLock = false
        todayBaseSeconds = fetchTodayTotal()
        startTimer()
        syncAmbient()
        if mode == .pomodoro { requestNotificationPermission() }
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
        } else {
            focusTime = focusAccumulated + (phase == .focus ? min(phaseAccumulated, focusDuration) : 0)
        }

        var saved: StudySession?
        if focusTime >= 5, let modelContext {
            let session = StudySession(
                startDate: sessionStart,
                endDate: .now,
                duration: focusTime,
                modeRaw: mode.rawValue,
                subject: selectedSubject
            )
            modelContext.insert(session)
            try? modelContext.save()
            saved = session
            celebrateIfGoalReached(sessionSeconds: focusTime)
        }
        reset()
        return saved
    }

    private func reset() {
        isRunning = false
        isPaused = false
        isAutoPaused = false
        pausedByLock = false
        phase = .focus
        phaseAccumulated = 0
        focusAccumulated = 0
        completedPomodoros = 0
        sessionStart = nil
        stopTimer()
        syncAmbient()
        updateDockBadge()
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
        updateDockBadge()
        syncAmbient()
        guard isRunning else { return }

        if isPaused {
            if isAutoPaused && !pausedByLock && currentIdleSeconds() < 2 {
                resume()
            }
            return
        }

        let idleLimitMinutes = UserDefaults.standard.integer(forKey: SettingsKeys.autoPauseIdleMinutes)
        if idleLimitMinutes > 0 && currentIdleSeconds() >= Double(idleLimitMinutes * 60) {
            pause(auto: true)
            return
        }

        if mode == .pomodoro, phaseElapsed >= currentPhaseDuration {
            advancePhase()
        }
    }

    private func advancePhase() {
        if phase == .focus {
            focusAccumulated += focusDuration
            completedPomodoros += 1
            phase = .pause
            playSound()
            notify(
                title: "Fokus geschafft 🎉",
                body: "Zeit für \(Int(breakDuration / 60)) Minuten Pause."
            )
        } else {
            phase = .focus
            playSound()
            notify(
                title: "Pause vorbei",
                body: "Weiter geht's mit dem nächsten Fokus-Block."
            )
        }
        phaseStart = .now
        phaseAccumulated = 0
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

    // MARK: - Ambient (Notch, Dock)

    private func syncAmbient() {
        let notchEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.notchLineEnabled)
        if isRunning && notchEnabled {
            notchOverlay.show(engine: self)
        } else {
            notchOverlay.hide()
        }
    }

    private func updateDockBadge() {
        let enabled = UserDefaults.standard.bool(forKey: SettingsKeys.dockBadgeEnabled)
        NSApp.dockTile.badgeLabel = (enabled && isRunning) ? displayString : nil
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
        playSound()
        notify(
            title: "Tagesziel erreicht 🔥",
            body: "Stark! Du hast heute \(formatDuration(after)) gelernt."
        )
    }

    private func playSound() {
        guard UserDefaults.standard.bool(forKey: SettingsKeys.soundsEnabled) else { return }
        NSSound(named: "Glass")?.play()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
