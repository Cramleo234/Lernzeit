import SwiftData
import SwiftUI

struct MenuBarView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.openWindow) private var openWindow
    @Query private var sessions: [StudySession]

    private var todayTotal: TimeInterval {
        let today = Calendar.current.startOfDay(for: .now)
        return sessions
            .filter { Calendar.current.startOfDay(for: $0.startDate) == today }
            .reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(engine.isRunning ? engine.displayString : localized("menu.ready"))
                    .font(engine.isRunning ? .system(size: 30, weight: .light, design: .rounded) : .headline)
                    .monospacedDigit()

                if engine.isRunning {
                    Text(statusLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                if !engine.isRunning {
                    Button {
                        engine.start()
                    } label: {
                        Label(localized("menu.start"), systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(engine.selectedSubject?.color ?? .accentColor)
                } else {
                    Button {
                        engine.isPaused ? engine.resume() : engine.pause()
                    } label: {
                        Label(
                            localized(engine.isPaused ? "common.resume" : "common.pause"),
                            systemImage: engine.isPaused ? "play.fill" : "pause.fill"
                        )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button {
                        engine.stop()
                    } label: {
                        Label(localized("menu.stop"), systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                }
            }
            .controlSize(.large)

            Divider()

            HStack {
                Text(localized("menu.studied_today"))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatDuration(todayTotal))
                    .monospacedDigit()
            }
            .font(.callout)

            VStack(spacing: 8) {
                HStack {
                    Button(localized("menu.open_app")) {
                        openWindow(id: "main")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    .buttonStyle(.link)
                    .font(.callout)

                    Spacer()

                    Button(localized("menu.mini_timer")) {
                        openWindow(id: "mini")
                    }
                    .buttonStyle(.link)
                    .font(.callout)
                }

                HStack {
                    SettingsLink {
                        Text(localized("navigation.settings"))
                    }
                    .buttonStyle(.link)
                    .font(.callout)

                    Spacer()

                    Button(localized("menu.quit")) {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.link)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private var statusLine: String {
        if engine.isAutoPaused { return localized("status.auto_paused") }
        if engine.isPaused { return localized("status.paused") }
        if engine.mode == .pomodoro {
            let phase = engine.phase.label
            let subject = engine.selectedSubject?.name
            return subject.map { localized("status.phase_subject", phase, $0) } ?? phase
        }
        if engine.mode == .countdown {
            return engine.selectedSubject.map { localized("status.timer_subject", $0.name) }
                ?? localized("status.timer_running")
        }
        return engine.selectedSubject?.name ?? localized("status.stopwatch_running")
    }
}
