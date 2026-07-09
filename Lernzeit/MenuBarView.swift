import SwiftData
import SwiftUI

struct MenuBarView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.modelContext) private var context
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
                Text(engine.isRunning ? engine.displayString : "Bereit zum Lernen")
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
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    Button {
                        engine.isPaused ? engine.resume() : engine.pause()
                    } label: {
                        Label(engine.isPaused ? "Weiter" : "Pause", systemImage: engine.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button {
                        engine.stop(in: context)
                    } label: {
                        Label("Stopp", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                }
            }
            .controlSize(.large)

            Divider()

            HStack {
                Text("Heute gelernt")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatDuration(todayTotal))
                    .monospacedDigit()
            }
            .font(.callout)

            HStack {
                Button("Lernzeit öffnen") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.link)
                .font(.callout)

                Spacer()

                Button("Beenden") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.link)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 290)
    }

    private var statusLine: String {
        if engine.isPaused { return "Pausiert" }
        if engine.mode == .pomodoro {
            let phase = engine.phase.label
            let subject = engine.selectedSubject?.name
            return subject.map { "\(phase) · \($0)" } ?? phase
        }
        return engine.selectedSubject?.name ?? "Stoppuhr läuft"
    }
}
