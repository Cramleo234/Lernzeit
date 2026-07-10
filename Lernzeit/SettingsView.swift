import AppKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.dailyGoalMinutes, store: .lernzeitShared) private var dailyGoalMinutes = 120
    @AppStorage(SettingsKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(SettingsKeys.breakMinutes) private var breakMinutes = 5
    @AppStorage(SettingsKeys.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsKeys.notchLineEnabled) private var notchLineEnabled = true
    @AppStorage(SettingsKeys.autoPauseOnLock) private var autoPauseOnLock = true
    @AppStorage(SettingsKeys.autoPauseIdleMinutes) private var autoPauseIdleMinutes = 3
    @AppStorage(SettingsKeys.appAppearance) private var appAppearance = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Section(localized("appearance.section")) {
                Picker(localized("appearance.theme"), selection: $appAppearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.label).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text(localized("appearance.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(localized("settings.goal_section")) {
                Stepper(
                    localized("settings.daily_goal", dailyGoalMinutes),
                    value: $dailyGoalMinutes,
                    in: 15...600,
                    step: 15
                )
            }

            Section(localized("settings.pomodoro_section")) {
                Stepper(localized("settings.focus_minutes", focusMinutes), value: $focusMinutes, in: 5...90, step: 5)
                Stepper(localized("settings.break_minutes", breakMinutes), value: $breakMinutes, in: 1...30, step: 1)
            }

            Section(localized("settings.auto_pause_section")) {
                Toggle(localized("settings.pause_on_lock"), isOn: $autoPauseOnLock)
                Picker(localized("settings.pause_on_idle"), selection: $autoPauseIdleMinutes) {
                    Text(localized("common.off")).tag(0)
                    Text(localized("settings.after_one_minute")).tag(1)
                    ForEach([3, 5, 10], id: \.self) { minutes in
                        Text(localized("settings.after_minutes", minutes)).tag(minutes)
                    }
                }
            }

            Section(localized("settings.display_sounds_section")) {
                Toggle(localized("settings.sound_phase_change"), isOn: $soundsEnabled)
                Toggle(localized("settings.notch_progress"), isOn: $notchLineEnabled)
                    .disabled(!hasNotch)
                Label(
                    hasNotch
                        ? localized("settings.notch_detected")
                        : localized("settings.no_notch"),
                    systemImage: hasNotch ? "checkmark.circle" : "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var hasNotch: Bool {
        NSScreen.screens.contains { $0.safeAreaInsets.top > 0 }
    }
}
