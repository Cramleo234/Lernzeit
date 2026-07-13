import AppKit
import Foundation

enum TimerSoundCue: CaseIterable, Equatable {
    case completion
    case breakEnded
    case goalReached

    var systemSoundName: NSSound.Name {
        switch self {
        case .completion:
            NSSound.Name("Hero")
        case .breakEnded:
            NSSound.Name("Ping")
        case .goalReached:
            NSSound.Name("Glass")
        }
    }
}

enum TimerSoundEvent {
    case countdownFinished
    case focusFinished
    case breakFinished
    case goalReached

    var cue: TimerSoundCue {
        switch self {
        case .countdownFinished, .focusFinished:
            .completion
        case .breakFinished:
            .breakEnded
        case .goalReached:
            .goalReached
        }
    }
}

protocol TimerSound: AnyObject {
    var volume: Float { get set }

    @discardableResult
    func stop() -> Bool

    @discardableResult
    func play() -> Bool
}

extension NSSound: TimerSound {}

@MainActor
final class TimerSoundPlayer {
    private let soundsEnabled: () -> Bool
    private var sounds: [TimerSoundCue: TimerSound] = [:]

    init(
        soundsEnabled: @escaping () -> Bool = {
            UserDefaults.standard.bool(forKey: SettingsKeys.soundsEnabled)
        },
        loadSound: (NSSound.Name) -> TimerSound? = { NSSound(named: $0) }
    ) {
        self.soundsEnabled = soundsEnabled
        for cue in TimerSoundCue.allCases {
            sounds[cue] = loadSound(cue.systemSoundName)
        }
    }

    func play(_ cue: TimerSoundCue) {
        guard soundsEnabled(), let sound = sounds[cue] else { return }
        for loadedSound in sounds.values {
            loadedSound.stop()
        }
        sound.volume = 1
        sound.play()
    }
}
