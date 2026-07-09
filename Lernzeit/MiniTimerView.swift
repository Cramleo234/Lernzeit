import SwiftUI

/// Kompakter, schwebender Timer, der über allen Fenstern bleibt.
struct MiniTimerView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(engine.isRunning ? engine.ambientColor : Color.secondary.opacity(0.4))
                .frame(width: 9, height: 9)

            Text(engine.isRunning ? engine.displayString : "Bereit")
                .font(.system(size: 26, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .frame(minWidth: 96)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    if !engine.isRunning {
                        Button {
                            engine.start()
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .buttonStyle(.glassProminent)
                        .tint(engine.selectedSubject?.color ?? .accentColor)
                    } else {
                        Button {
                            engine.isPaused ? engine.resume() : engine.pause()
                        } label: {
                            Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                        }
                        .buttonStyle(.glass)

                        Button {
                            engine.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.red)
                    }
                }
            }
            .controlSize(.large)

            Button {
                dismissWindow(id: "mini")
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .help("Mini-Timer schließen")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
