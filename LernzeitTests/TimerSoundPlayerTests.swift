import AppKit
import XCTest
@testable import Lernzeit

@MainActor
final class TimerSoundPlayerTests: XCTestCase {
    func testCuesUseDifferentAvailableSystemSounds() {
        let names = TimerSoundCue.allCases.map(\.systemSoundName)

        XCTAssertEqual(Set(names).count, TimerSoundCue.allCases.count)
        for name in names {
            XCTAssertNotNil(NSSound(named: name), "Missing system sound: \(name)")
        }
    }

    func testTimerEventsChooseExpectedCues() {
        XCTAssertEqual(TimerSoundEvent.countdownFinished.cue, .completion)
        XCTAssertEqual(TimerSoundEvent.focusFinished.cue, .completion)
        XCTAssertEqual(TimerSoundEvent.breakFinished.cue, .breakEnded)
        XCTAssertEqual(TimerSoundEvent.goalReached.cue, .goalReached)
    }

    func testPlayerRetainsLoadedSoundAndPlaysRequestedCue() {
        weak var retainedSound: SoundSpy?
        let player = TimerSoundPlayer(
            soundsEnabled: { true },
            loadSound: { name in
                guard name == TimerSoundCue.completion.systemSoundName else { return nil }
                let sound = SoundSpy()
                retainedSound = sound
                return sound
            }
        )

        XCTAssertNotNil(retainedSound)

        player.play(.completion)

        XCTAssertEqual(retainedSound?.stopCallCount, 1)
        XCTAssertEqual(retainedSound?.playCallCount, 1)
        XCTAssertEqual(retainedSound?.volume, 1)
    }

    func testPlayerStaysSilentWhenSoundsAreDisabled() {
        let sound = SoundSpy()
        let player = TimerSoundPlayer(
            soundsEnabled: { false },
            loadSound: { _ in sound }
        )

        player.play(.completion)

        XCTAssertEqual(sound.playCallCount, 0)
    }

    func testPlayerStopsOtherCuesBeforePlayingRequestedCue() {
        let completionSound = SoundSpy()
        let breakSound = SoundSpy()
        let player = TimerSoundPlayer(
            soundsEnabled: { true },
            loadSound: { name in
                switch name {
                case TimerSoundCue.completion.systemSoundName:
                    completionSound
                case TimerSoundCue.breakEnded.systemSoundName:
                    breakSound
                default:
                    nil
                }
            }
        )

        player.play(.completion)

        XCTAssertEqual(completionSound.stopCallCount, 1)
        XCTAssertEqual(breakSound.stopCallCount, 1)
        XCTAssertEqual(completionSound.playCallCount, 1)
        XCTAssertEqual(breakSound.playCallCount, 0)
    }
}

private final class SoundSpy: TimerSound {
    var volume: Float = 0
    private(set) var stopCallCount = 0
    private(set) var playCallCount = 0

    @discardableResult
    func stop() -> Bool {
        stopCallCount += 1
        return true
    }

    @discardableResult
    func play() -> Bool {
        playCallCount += 1
        return true
    }
}
