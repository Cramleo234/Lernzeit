import AppKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.dailyGoalMinutes, store: .lernzeitShared) private var dailyGoalMinutes = 120
    @AppStorage(SettingsKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(SettingsKeys.breakMinutes) private var breakMinutes = 5
    @AppStorage(SettingsKeys.longBreakMinutes) private var longBreakMinutes = 20
    @AppStorage(SettingsKeys.roundsPerCycle) private var roundsPerCycle = 4
    @AppStorage(SettingsKeys.autoStartNextPhase) private var autoStartNextPhase = true
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
                Text(localized("appearance.description")).font(.caption).foregroundStyle(.secondary)
            }

            Section(localized("settings.goal_section")) {
                Stepper(localized("settings.daily_goal", dailyGoalMinutes), value: $dailyGoalMinutes, in: 15...600, step: 15)
            }

            Section(localized("settings.pomodoro_section")) {
                Stepper(localized("settings.focus_minutes", focusMinutes), value: $focusMinutes, in: 5...120, step: 5)
                Stepper(localized("settings.break_minutes", breakMinutes), value: $breakMinutes, in: 1...30)
                Stepper(localized("presets.long_break_minutes", longBreakMinutes), value: $longBreakMinutes, in: 5...60, step: 5)
                Stepper(localized("presets.rounds", roundsPerCycle), value: $roundsPerCycle, in: 1...12)
                Toggle(localized("presets.auto_start"), isOn: $autoStartNextPhase)
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
                Text(localized("settings.break_idle_note")).font(.caption).foregroundStyle(.secondary)
            }

            Section(localized("settings.display_sounds_section")) {
                Toggle(localized("settings.sound_phase_change"), isOn: $soundsEnabled)
                Toggle(localized("settings.notch_progress"), isOn: $notchLineEnabled).disabled(!hasNotch)
                Label(
                    hasNotch ? localized("settings.notch_detected") : localized("settings.no_notch"),
                    systemImage: hasNotch ? "checkmark.circle" : "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            DataManagementView()
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, idealWidth: 560, maxWidth: 640, maxHeight: .infinity, alignment: .top)
    }

    private var hasNotch: Bool {
        NSScreen.screens.contains { $0.safeAreaInsets.top > 0 }
    }
}
