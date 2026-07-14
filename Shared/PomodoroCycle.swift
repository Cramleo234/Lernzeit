import Foundation

struct PomodoroPlan: Codable, Equatable {
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let roundsPerCycle: Int
    let autoStartNextPhase: Bool

    init(
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        roundsPerCycle: Int,
        autoStartNextPhase: Bool
    ) {
        self.focusMinutes = max(1, focusMinutes)
        self.shortBreakMinutes = max(1, shortBreakMinutes)
        self.longBreakMinutes = max(1, longBreakMinutes)
        self.roundsPerCycle = max(1, roundsPerCycle)
        self.autoStartNextPhase = autoStartNextPhase
    }
}

struct PomodoroCycle: Equatable {
    private(set) var phase: PomodoroPhase = .focus
    private(set) var completedFocusRounds = 0

    func duration(using plan: PomodoroPlan) -> TimeInterval {
        let minutes: Int
        switch phase {
        case .focus:
            minutes = plan.focusMinutes
        case .shortBreak:
            minutes = plan.shortBreakMinutes
        case .longBreak:
            minutes = plan.longBreakMinutes
        }
        return TimeInterval(minutes * 60)
    }

    @discardableResult
    mutating func completeCurrentPhase(using plan: PomodoroPlan) -> PomodoroPhase {
        if phase == .focus {
            completedFocusRounds += 1
            phase = completedFocusRounds.isMultiple(of: plan.roundsPerCycle) ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }
        return phase
    }

    mutating func reset() {
        phase = .focus
        completedFocusRounds = 0
    }
}
