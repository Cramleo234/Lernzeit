import AppKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.dailyGoalMinutes, store: .lernzeitShared) private var dailyGoalMinutes = 120
    @AppStorage(SettingsKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(SettingsKeys.breakMinutes) private var breakMinutes = 5
    @AppStorage(SettingsKeys.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsKeys.dockBadgeEnabled) private var dockBadgeEnabled = true
    @AppStorage(SettingsKeys.notchLineEnabled) private var notchLineEnabled = true
    @AppStorage(SettingsKeys.autoPauseOnLock) private var autoPauseOnLock = true
    @AppStorage(SettingsKeys.autoPauseIdleMinutes) private var autoPauseIdleMinutes = 3
    @AppStorage(SettingsKeys.appAppearance) private var appAppearance = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Section("Darstellung") {
                Picker("Theme", selection: $appAppearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.label).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text("Wähle „Dunkel“, um Lernzeit unabhängig von der macOS-Einstellung dauerhaft im Dark Theme zu verwenden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Ziel") {
                Stepper(
                    "Tagesziel: \(dailyGoalMinutes) min",
                    value: $dailyGoalMinutes,
                    in: 15...600,
                    step: 15
                )
            }

            Section("Pomodoro") {
                Stepper("Fokus: \(focusMinutes) min", value: $focusMinutes, in: 5...90, step: 5)
                Stepper("Pause: \(breakMinutes) min", value: $breakMinutes, in: 1...30, step: 1)
            }

            Section("Automatische Pause") {
                Toggle("Bei Bildschirmsperre pausieren", isOn: $autoPauseOnLock)
                Picker("Bei Inaktivität pausieren", selection: $autoPauseIdleMinutes) {
                    Text("Aus").tag(0)
                    Text("Nach 1 min").tag(1)
                    Text("Nach 3 min").tag(3)
                    Text("Nach 5 min").tag(5)
                    Text("Nach 10 min").tag(10)
                }
            }

            Section("Anzeige & Töne") {
                Toggle("Ton bei Phasenwechsel", isOn: $soundsEnabled)
                Toggle("Restzeit am Dock-Icon", isOn: $dockBadgeEnabled)
                Toggle("Fortschrittslinie um die Notch", isOn: $notchLineEnabled)
                    .disabled(!hasNotch)
                Label(
                    hasNotch
                        ? "Notch erkannt — die Linie erscheint bei laufendem Timer um die Notch."
                        : "Kein Display mit Notch erkannt. Der Fortschritt wird stattdessen als Ring im Menüleisten-Icon angezeigt.",
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
