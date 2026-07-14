import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var name: String
    var colorHex: String
    var createdAt: Date
    /// Null deaktiviert das optionale Wochenziel.
    var weeklyGoalMinutes: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \StudySession.subject)
    var sessions: [StudySession] = []

    init(name: String, colorHex: String, weeklyGoalMinutes: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = .now
        self.weeklyGoalMinutes = max(0, weeklyGoalMinutes)
    }

    var color: Color { Color(hex: colorHex) }
}

@Model
final class TimerPreset {
    var name: String
    var modeRaw: String
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var roundsPerCycle: Int
    var countdownMinutes: Int
    var autoStartNextPhase: Bool
    var createdAt: Date
    var subject: Subject?

    init(
        name: String,
        modeRaw: String,
        focusMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 20,
        roundsPerCycle: Int = 4,
        countdownMinutes: Int = 25,
        autoStartNextPhase: Bool = true,
        subject: Subject? = nil
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.modeRaw = TimerMode(rawValue: modeRaw)?.rawValue ?? TimerMode.pomodoro.rawValue
        self.focusMinutes = max(1, focusMinutes)
        self.shortBreakMinutes = max(1, shortBreakMinutes)
        self.longBreakMinutes = max(1, longBreakMinutes)
        self.roundsPerCycle = max(1, roundsPerCycle)
        self.countdownMinutes = max(1, countdownMinutes)
        self.autoStartNextPhase = autoStartNextPhase
        self.createdAt = .now
        self.subject = subject
    }

    var mode: TimerMode {
        TimerMode(rawValue: modeRaw) ?? .pomodoro
    }

    var pomodoroPlan: PomodoroPlan {
        PomodoroPlan(
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            roundsPerCycle: roundsPerCycle,
            autoStartNextPhase: autoStartNextPhase
        )
    }
}

@Model
final class StudySession {
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var modeRaw: String
    var note: String = ""
    var presetName: String = ""
    var completedFocusRounds: Int = 0
    var subject: Subject?

    init(
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        modeRaw: String,
        subject: Subject? = nil,
        presetName: String = "",
        completedFocusRounds: Int = 0
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.modeRaw = modeRaw
        self.subject = subject
        self.presetName = presetName
        self.completedFocusRounds = max(0, completedFocusRounds)
    }

    var isPomodoro: Bool { modeRaw == "pomodoro" }
    var isCountdown: Bool { modeRaw == "countdown" }
}
