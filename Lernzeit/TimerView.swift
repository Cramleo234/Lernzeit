import SwiftData
import SwiftUI

struct TimerView: View {
    @Environment(TimerEngine.self) private var engine
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @Query(sort: \TimerPreset.createdAt) private var presets: [TimerPreset]
    @AppStorage(SettingsKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(SettingsKeys.breakMinutes) private var breakMinutes = 5
    @AppStorage(SettingsKeys.longBreakMinutes) private var longBreakMinutes = 20
    @AppStorage(SettingsKeys.roundsPerCycle) private var roundsPerCycle = 4
    @AppStorage(SettingsKeys.autoStartNextPhase) private var autoStartNextPhase = true
    @AppStorage(SettingsKeys.customTimerMinutes) private var customTimerMinutes = 25
    @State private var finishedSession: StudySession?
    @Namespace private var glassNamespace
    private let quickTimerMinutes = [10, 15, 20, 25, 30, 45, 60, 90]

    var body: some View {
        @Bindable var engine = engine
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            timerHeader

            Picker(localized("timer.mode_label"), selection: modeBinding) {
                ForEach(TimerMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 320)
            .disabled(engine.isRunning)

            if !engine.isRunning, !presets.isEmpty {
                presetPicker
            }

            subjectPicker

            timeDisplay

            controls

            if engine.isAutoPaused {
                Label(
                    localized("timer.auto_paused_detail"),
                    systemImage: "moon.zzz"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if !engine.isRunning, engine.activePresetName.isEmpty {
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
                Text(localized("timer.title"))
            }
            .font(.system(size: 34, weight: .semibold, design: .rounded))

            Text(localized("timer.subtitle"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private var modeBinding: Binding<TimerMode> {
        Binding(
            get: { engine.mode },
            set: { mode in
                engine.clearPresetConfiguration()
                engine.mode = mode
            }
        )
    }

    private var presetPicker: some View {
        Menu {
            Button(localized("presets.custom_settings")) { engine.clearPresetConfiguration() }
            Divider()
            ForEach(presets) { preset in
                Button(preset.name) { engine.apply(preset) }
            }
        } label: {
            Label(
                engine.activePresetName.isEmpty ? localized("presets.choose") : engine.activePresetName,
                systemImage: "square.stack.3d.up"
            )
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .fixedSize()
    }

    private var subjectPicker: some View {
        Menu {
            Button(localized("common.no_subject")) { engine.selectedSubject = nil }
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
                Text(engine.selectedSubject?.name ?? localized("common.no_subject"))
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

                if engine.mode == .pomodoro {
                    Text(localized("timer.round_status", engine.roundInCycle, engine.pomodoroPlan.roundsPerCycle))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    if engine.completedPomodoros > 0 {
                        Text(localized("timer.completed_rounds", engine.completedPomodoros))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .frame(height: engine.mode == .stopwatch ? 120 : 290)
    }

    private var timerStatusText: String {
        if engine.isAutoPaused { return localized("status.auto_paused") }
        if engine.isPaused { return localized("status.paused") }

        switch engine.mode {
        case .stopwatch:
            return localized(engine.isRunning ? "status.stopwatch_running" : "status.stopwatch_ready")
        case .countdown:
            return localized(engine.isRunning ? "status.timer_running" : "status.timer_ready")
        case .pomodoro:
            return engine.isRunning ? engine.phase.label : localized("status.pomodoro_ready")
        }
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                if !engine.isRunning {
                    Button {
                        withAnimation(.spring(duration: 0.4)) { engine.start() }
                    } label: {
                        Label(localized("timer.start"), systemImage: "play.fill")
                            .frame(minWidth: 150)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(engine.selectedSubject?.color ?? .accentColor)
                    .controlSize(.extraLarge)
                    .glassEffectID("primary", in: glassNamespace)
                    .keyboardShortcut(.space, modifiers: [])
                } else {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            engine.isPaused ? engine.resume() : engine.pause()
                        }
                    } label: {
                        Label(
                            localized(engine.isPaused ? "common.resume" : "common.pause"),
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
                        Label(localized("common.stop"), systemImage: "stop.fill")
                            .frame(minWidth: 100)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .controlSize(.extraLarge)
                    .glassEffectID("primary", in: glassNamespace)
                }
            }
            if engine.isRunning, engine.mode == .pomodoro, engine.phase.isBreak {
                HStack(spacing: 12) {
                    Button(localized("timer.extend_break"), systemImage: "plus.circle") {
                        engine.extendBreak()
                    }
                    .buttonStyle(.glass)
                    Button(localized("timer.skip_break"), systemImage: "forward.end.fill") {
                        engine.skipBreak()
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.small)
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
        Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
            GridRow {
                Stepper(localized("settings.focus_minutes", focusMinutes), value: $focusMinutes, in: 5...120, step: 5)
                Stepper(localized("settings.break_minutes", breakMinutes), value: $breakMinutes, in: 1...30)
            }
            GridRow {
                Stepper(localized("presets.long_break_minutes", longBreakMinutes), value: $longBreakMinutes, in: 5...60, step: 5)
                Stepper(localized("presets.rounds", roundsPerCycle), value: $roundsPerCycle, in: 1...12)
            }
            GridRow {
                Toggle(localized("presets.auto_start"), isOn: $autoStartNextPhase)
                    .gridCellColumns(2)
            }
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

                TextField(localized("common.minutes"), value: $customTimerMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()
                    .frame(width: 70)
                    .onSubmit { clampCustomTimerMinutes() }
                    .onChange(of: customTimerMinutes) { _, _ in clampCustomTimerMinutes() }

                Text(localized("common.minutes"))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(quickTimerMinutes, id: \.self) { minutes in
                    Button("\(minutes)") {
                        customTimerMinutes = minutes
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel(localized("timer.minutes_accessibility", minutes))
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
            Text(localized("timer.session_saved"))
                .font(.headline)
            Text(localized(
                "timer.session_summary",
                formatDuration(session.duration),
                session.subject?.name ?? localized("common.no_subject")
            ))
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField(localized("timer.note_placeholder"), text: $session.note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .frame(width: 340)

            Button(localized("common.done")) {
                try? context.save()
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
    }
}
