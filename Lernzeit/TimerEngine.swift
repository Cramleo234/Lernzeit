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

@MainActor
@Observable
final class TimerEngine {
    var mode: TimerMode = .stopwatch
    var phase: PomodoroPhase = .focus
    var isRunning = false
    var isPaused = false
    var completedPomodoros = 0
    var selectedSubject: Subject?

    private(set) var now: Date = .now

    private var timer: Timer?
    private var sessionStart: Date?
    private var phaseStart: Date = .now
    private var phaseAccumulated: TimeInterval = 0
    private var focusAccumulated: TimeInterval = 0

    var focusDuration: TimeInterval {
        let minutes = UserDefaults.standard.integer(forKey: "focusMinutes")
        return TimeInterval(minutes > 0 ? minutes : 25) * 60
    }

    var breakDuration: TimeInterval {
        let minutes = UserDefaults.standard.integer(forKey: "breakMinutes")
        return TimeInterval(minutes > 0 ? minutes : 5) * 60
    }

    var currentPhaseDuration: TimeInterval {
        phase == .focus ? focusDuration : breakDuration
    }

    var phaseElapsed: TimeInterval {
        guard isRunning else { return 0 }
        if isPaused { return phaseAccumulated }
        return phaseAccumulated + now.timeIntervalSince(phaseStart)
    }

    /// Was groß angezeigt wird: Stoppuhr zählt hoch, Pomodoro zählt runter.
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
        startTimer()
        if mode == .pomodoro { requestNotificationPermission() }
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        phaseAccumulated += Date.now.timeIntervalSince(phaseStart)
        isPaused = true
        stopTimer()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        phaseStart = .now
        isPaused = false
        startTimer()
    }

    func stop(in context: ModelContext) {
        guard isRunning, let sessionStart else { return }
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
        stopTimer()
        if focusTime >= 5 {
            let session = StudySession(
                startDate: sessionStart,
                endDate: .now,
                duration: focusTime,
                modeRaw: mode.rawValue,
                subject: selectedSubject
            )
            context.insert(session)
            try? context.save()
        }
        reset()
    }

    private func reset() {
        isRunning = false
        isPaused = false
        phase = .focus
        phaseAccumulated = 0
        focusAccumulated = 0
        completedPomodoros = 0
        sessionStart = nil
    }

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
        guard mode == .pomodoro, isRunning, !isPaused else { return }
        if phaseElapsed >= currentPhaseDuration {
            advancePhase()
        }
    }

    private func advancePhase() {
        if phase == .focus {
            focusAccumulated += focusDuration
            completedPomodoros += 1
            phase = .pause
            notify(
                title: "Fokus geschafft 🎉",
                body: "Zeit für \(Int(breakDuration / 60)) Minuten Pause."
            )
        } else {
            phase = .focus
            notify(
                title: "Pause vorbei",
                body: "Weiter geht's mit dem nächsten Fokus-Block."
            )
        }
        phaseStart = .now
        phaseAccumulated = 0
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
