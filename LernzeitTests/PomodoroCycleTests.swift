import XCTest
@testable import Lernzeit

final class PomodoroCycleTests: XCTestCase {
    func testFourthCompletedFocusRoundStartsLongBreakThenReturnsToFocus() {
        let plan = PomodoroPlan(
            focusMinutes: 25,
            shortBreakMinutes: 5,
            longBreakMinutes: 20,
            roundsPerCycle: 4,
            autoStartNextPhase: true
        )
        var cycle = PomodoroCycle()

        for _ in 0..<3 {
            XCTAssertEqual(cycle.completeCurrentPhase(using: plan), .shortBreak)
            XCTAssertEqual(cycle.completeCurrentPhase(using: plan), .focus)
        }

        XCTAssertEqual(cycle.completeCurrentPhase(using: plan), .longBreak)
        XCTAssertEqual(cycle.duration(using: plan), 20 * 60)
        XCTAssertEqual(cycle.completeCurrentPhase(using: plan), .focus)
        XCTAssertEqual(cycle.completedFocusRounds, 4)
    }

    func testPlanClampsUnsafeValues() {
        let plan = PomodoroPlan(
            focusMinutes: 0,
            shortBreakMinutes: 0,
            longBreakMinutes: 0,
            roundsPerCycle: 0,
            autoStartNextPhase: false
        )

        XCTAssertEqual(plan.focusMinutes, 1)
        XCTAssertEqual(plan.shortBreakMinutes, 1)
        XCTAssertEqual(plan.longBreakMinutes, 1)
        XCTAssertEqual(plan.roundsPerCycle, 1)
        XCTAssertFalse(plan.autoStartNextPhase)
    }
}
