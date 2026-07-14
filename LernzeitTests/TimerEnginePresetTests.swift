import XCTest
@testable import Lernzeit

@MainActor
final class TimerEnginePresetTests: XCTestCase {
    func testApplyingPresetCopiesConfigurationWithoutStartingTimer() {
        let subject = Subject(name: "Biologie", colorHex: "#5CC98A")
        let preset = TimerPreset(
            name: "Bio-Zyklus",
            modeRaw: TimerMode.pomodoro.rawValue,
            focusMinutes: 40,
            shortBreakMinutes: 8,
            longBreakMinutes: 20,
            roundsPerCycle: 3,
            countdownMinutes: 25,
            autoStartNextPhase: false,
            subject: subject
        )
        let engine = TimerEngine()

        engine.apply(preset)

        XCTAssertEqual(engine.mode, .pomodoro)
        XCTAssertTrue(engine.selectedSubject === subject)
        XCTAssertEqual(engine.activePresetName, "Bio-Zyklus")
        XCTAssertEqual(engine.focusDuration, 40 * 60)
        XCTAssertEqual(engine.currentPhaseDuration, 40 * 60)
        XCTAssertEqual(engine.pomodoroPlan.roundsPerCycle, 3)
        XCTAssertFalse(engine.isRunning)
    }
}
