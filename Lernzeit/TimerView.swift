import SwiftData
import SwiftUI

struct TimerView: View {
    @Environment(TimerEngine.self) private var engine
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @AppStorage(SettingsKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(SettingsKeys.breakMinutes) private var breakMinutes = 5
    @AppStorage(SettingsKeys.customTimerMinutes) private var customTimerMinutes = 25
    @State private var finishedSession: StudySession?
    @Namespace private var glassNamespace
    private let quickTimerMinutes = [10, 15, 20, 25, 30, 45, 60, 90]

    var body: some View {
        @Bindable var engine = engine
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            timerHeader

            Picker("Modus", selection: $engine.mode) {
                ForEach(TimerMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 320)
            .disabled(engine.isRunning)

            subjectPicker

            timeDisplay

            controls

            if engine.isAutoPaused {
                Label(
                    "Automatisch pausiert — geht bei Aktivität von selbst weiter",
                    systemImage: "moon.zzz"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if !engine.isRunning {
                timerSettings
            }

            Spacer(minLength: 0)
        }
        .padding(32)
        .sheet(item: $finishedSession) { session in
            SessionNoteSheet(session: session)
        }
    }

    private var timerHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .symbolRenderingMode(.hierarchical)
                Text("Lern-Timer")
            }
            .font(.system(size: 34, weight: .semibold, design: .rounded))

            Text("Stoppuhr, eigenen Timer oder Pomodoro starten.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private var subjectPicker: some View {
        Menu {
            Button("Ohne Fach") { engine.selectedSubject = nil }
            if !subjects.isEmpty {
                Divider()
                ForEach(subjects) { subject in
                    Button(subject.name) { engine.selectedSubject = subject }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(engine.selectedSubject?.color ?? Color.secondary.opacity(0.5))
                    .frame(width: 9, height: 9)
                Text(engine.selectedSubject?.name ?? "Ohne Fach")
            }
            .padding(.horizontal, 4)
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .controlSize(.large)
        .fixedSize()
    }

    private var timeDisplay: some View {
        ZStack {
            if engine.mode != .stopwatch {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                    .frame(width: 270, height: 270)
                Circle()
                    .trim(from: 0, to: engine.phaseProgress)
                    .stroke(
                        engine.ambientColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 270, height: 270)
                    .animation(.linear(duration: 0.5), value: engine.phaseProgress)
            }

            VStack(spacing: 6) {
                Text(engine.displayString)
                    .font(.system(size: engine.mode == .stopwatch ? 64 : 56, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(timerStatusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if engine.mode == .pomodoro && engine.completedPomodoros > 0 {
                    Text("🍅 × \(engine.completedPomodoros)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: engine.mode == .stopwatch ? 120 : 290)
    }

    private var timerStatusText: String {
        if engine.isAutoPaused { return "Automatisch pausiert" }
        if engine.isPaused { return "Pausiert" }

        switch engine.mode {
        case .stopwatch:
            return engine.isRunning ? "Stoppuhr läuft" : "Stoppuhr bereit"
        case .countdown:
            return engine.isRunning ? "Timer läuft" : "Timer bereit"
        case .pomodoro:
            return engine.isRunning ? engine.phase.label : "Pomodoro bereit"
        }
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                if !engine.isRunning {
                    Button {
                        withAnimation(.spring(duration: 0.4)) { engine.start() }
                    } label: {
                        Label("Timer starten", systemImage: "play.fill")
                            .frame(minWidth: 150)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(engine.selectedSubject?.color ?? .accentColor)
                    .controlSize(.extraLarge)
                    .glassEffectID("primary", in: glassNamespace)
                } else {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            engine.isPaused ? engine.resume() : engine.pause()
                        }
                    } label: {
                        Label(
                            engine.isPaused ? "Weiter" : "Pause",
                            systemImage: engine.isPaused ? "play.fill" : "pause.fill"
                        )
                        .frame(minWidth: 100)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.extraLarge)
                    .glassEffectID("secondary", in: glassNamespace)

                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            finishedSession = engine.stop()
                        }
                    } label: {
                        Label("Beenden", systemImage: "stop.fill")
                            .frame(minWidth: 100)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .controlSize(.extraLarge)
                    .glassEffectID("primary", in: glassNamespace)
                }
            }
        }
    }

    @ViewBuilder
    private var timerSettings: some View {
        switch engine.mode {
        case .countdown:
            countdownSettings
        case .pomodoro:
            pomodoroSettings
        case .stopwatch:
            EmptyView()
        }
    }

    private var pomodoroSettings: some View {
        HStack(spacing: 24) {
            Stepper("Fokus: \(focusMinutes) min", value: $focusMinutes, in: 5...90, step: 5)
            Stepper("Pause: \(breakMinutes) min", value: $breakMinutes, in: 1...30, step: 1)
        }
        .font(.callout)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var countdownSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Stepper("", value: $customTimerMinutes, in: 1...600, step: 1)
                    .labelsHidden()

                TextField("Minuten", value: $customTimerMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()
                    .frame(width: 70)
                    .onSubmit { clampCustomTimerMinutes() }
                    .onChange(of: customTimerMinutes) { _, _ in clampCustomTimerMinutes() }

                Text("Minuten")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(quickTimerMinutes, id: \.self) { minutes in
                    Button("\(minutes)") {
                        customTimerMinutes = minutes
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("\(minutes) Minuten")
                }
            }
        }
        .font(.callout)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func clampCustomTimerMinutes() {
        customTimerMinutes = min(600, max(1, customTimerMinutes))
    }
}

struct SessionNoteSheet: View {
    @Bindable var session: StudySession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 18) {
            Text("Session gespeichert")
                .font(.headline)
            Text("\(formatDuration(session.duration)) · \(session.subject?.name ?? "Ohne Fach")")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("Was hast du gelernt? (optional)", text: $session.note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .frame(width: 340)

            Button("Fertig") {
                try? context.save()
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
    }
}
