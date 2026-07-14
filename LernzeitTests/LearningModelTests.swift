import XCTest
@testable import Lernzeit

final class LearningModelTests: XCTestCase {
    func testPresetBuildsSafePomodoroPlanAndKeepsSubject() {
        let subject = Subject(name: "Mathematik", colorHex: "#4E7CF6", weeklyGoalMinutes: 180)
        let preset = TimerPreset(
            name: "Mathe intensiv",
            modeRaw: TimerMode.pomodoro.rawValue,
            focusMinutes: 50,
            shortBreakMinutes: 10,
            longBreakMinutes: 25,
            roundsPerCycle: 4,
            countdownMinutes: 25,
            autoStartNextPhase: true,
            subject: subject
        )

        XCTAssertEqual(subject.weeklyGoalMinutes, 180)
        XCTAssertEqual(preset.mode, .pomodoro)
        XCTAssertEqual(preset.subject?.name, "Mathematik")
        XCTAssertEqual(
            preset.pomodoroPlan,
            PomodoroPlan(
                focusMinutes: 50,
                shortBreakMinutes: 10,
                longBreakMinutes: 25,
                roundsPerCycle: 4,
                autoStartNextPhase: true
            )
        )
    }

    func testSessionStoresPresetAndCompletedFocusRounds() {
        let session = StudySession(
            startDate: .now,
            endDate: .now,
            duration: 3_000,
            modeRaw: TimerMode.pomodoro.rawValue,
            presetName: "Mathe intensiv",
            completedFocusRounds: 2
        )

        XCTAssertEqual(session.presetName, "Mathe intensiv")
        XCTAssertEqual(session.completedFocusRounds, 2)
    }
}
