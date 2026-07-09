import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var name: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \StudySession.subject)
    var sessions: [StudySession] = []

    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = .now
    }

    var color: Color { Color(hex: colorHex) }
}

@Model
final class StudySession {
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var modeRaw: String
    var note: String = ""
    var subject: Subject?

    init(startDate: Date, endDate: Date, duration: TimeInterval, modeRaw: String, subject: Subject? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.modeRaw = modeRaw
        self.subject = subject
    }

    var isPomodoro: Bool { modeRaw == "pomodoro" }
    var isCountdown: Bool { modeRaw == "countdown" }
}
