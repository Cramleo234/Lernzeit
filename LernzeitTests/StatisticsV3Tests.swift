import XCTest
@testable import Lernzeit

final class StatisticsV3Tests: XCTestCase {
    func testWeekTotalSeparatesCurrentAndPreviousWeekForSubject() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: reference)!
        let subject = Subject(name: "Chemie", colorHex: "#5CC98A")
        let other = Subject(name: "Deutsch", colorHex: "#A06CF5")
        let sessions = [
            StudySession(startDate: currentWeek.start.addingTimeInterval(3_600), endDate: currentWeek.start.addingTimeInterval(5_400), duration: 1_800, modeRaw: "stopwatch", subject: subject),
            StudySession(startDate: currentWeek.start.addingTimeInterval(7_200), endDate: currentWeek.start.addingTimeInterval(10_800), duration: 3_600, modeRaw: "stopwatch", subject: other),
            StudySession(startDate: currentWeek.start.addingTimeInterval(-3_600), endDate: currentWeek.start.addingTimeInterval(-1_800), duration: 1_800, modeRaw: "stopwatch", subject: subject),
        ]

        XCTAssertEqual(Statistics.weekTotal(sessions: sessions, subject: subject, containing: reference, calendar: calendar), 1_800)
        XCTAssertEqual(Statistics.weekTotal(sessions: sessions, subject: nil, containing: reference, calendar: calendar), 5_400)
    }

    func testPresetTotalsIgnoreUnnamedSessions() {
        let sessions = [
            StudySession(startDate: .now, endDate: .now, duration: 1_200, modeRaw: "pomodoro", presetName: "Mathe"),
            StudySession(startDate: .now, endDate: .now, duration: 600, modeRaw: "pomodoro", presetName: "Mathe"),
            StudySession(startDate: .now, endDate: .now, duration: 900, modeRaw: "stopwatch"),
        ]

        XCTAssertEqual(Statistics.presetTotals(sessions: sessions), ["Mathe": 1_800])
    }
}
