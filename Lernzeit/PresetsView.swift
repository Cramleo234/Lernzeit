import SwiftData
import SwiftUI

struct PresetsView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.modelContext) private var context
    @Query(sort: \TimerPreset.createdAt) private var presets: [TimerPreset]
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @State private var editorPresented = false
    @State private var editingPreset: TimerPreset?

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localized("presets.title"))
                        .font(.title2.weight(.semibold))
                    Text(localized("presets.subtitle"))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(localized("presets.add"), systemImage: "plus") {
                    editingPreset = nil
                    editorPresented = true
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut("n", modifiers: [.command])
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            if presets.isEmpty {
                ContentUnavailableView(
                    localized("presets.empty_title"),
                    systemImage: "square.stack.3d.up",
                    description: Text(localized("presets.empty_description"))
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(presets) { preset in
                        presetRow(preset)
                    }
                    .onDelete(perform: deletePresets)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $editorPresented) {
            PresetEditorSheet(preset: editingPreset, subjects: subjects)
        }
    }

    private func presetRow(_ preset: TimerPreset) -> some View {
        HStack(spacing: 14) {
            Image(systemName: preset.mode == .pomodoro ? "repeat.circle.fill" : preset.mode == .countdown ? "timer" : "stopwatch.fill")
                .font(.title2)
                .foregroundStyle(preset.subject?.color ?? .accentColor)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name).font(.headline)
                Text(summary(preset))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let subject = preset.subject {
                Label(subject.name, systemImage: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(localized("presets.edit"), systemImage: "pencil") {
                editingPreset = preset
                editorPresented = true
            }
            .buttonStyle(.borderless)
            Button(localized("presets.start"), systemImage: "play.fill") {
                engine.apply(preset)
                engine.start()
            }
            .buttonStyle(.glassProminent)
            .disabled(engine.isRunning)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }

    private func summary(_ preset: TimerPreset) -> String {
        switch preset.mode {
        case .pomodoro:
            localized("presets.summary_pomodoro", preset.focusMinutes, preset.shortBreakMinutes, preset.roundsPerCycle, preset.longBreakMinutes)
        case .countdown:
            localized("presets.summary_countdown", preset.countdownMinutes)
        case .stopwatch:
            localized("presets.summary_stopwatch")
        }
    }

    private func deletePresets(at offsets: IndexSet) {
        for offset in offsets { context.delete(presets[offset]) }
        try? context.save()
    }
}

struct PresetEditorSheet: View {
    let preset: TimerPreset?
    let subjects: [Subject]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var mode = TimerMode.pomodoro
    @State private var focusMinutes = 25
    @State private var shortBreakMinutes = 5
    @State private var longBreakMinutes = 20
    @State private var roundsPerCycle = 4
    @State private var countdownMinutes = 25
    @State private var autoStart = true
    @State private var subject: Subject?

    var body: some View {
        Form {
            TextField(localized("presets.name"), text: $name)
            Picker(localized("timer.mode_label"), selection: $mode) {
                ForEach(TimerMode.allCases) { Text($0.label).tag($0) }
            }
            if mode == .pomodoro {
                Stepper(localized("settings.focus_minutes", focusMinutes), value: $focusMinutes, in: 5...120, step: 5)
                Stepper(localized("settings.break_minutes", shortBreakMinutes), value: $shortBreakMinutes, in: 1...30)
                Stepper(localized("presets.long_break_minutes", longBreakMinutes), value: $longBreakMinutes, in: 5...60, step: 5)
                Stepper(localized("presets.rounds", roundsPerCycle), value: $roundsPerCycle, in: 1...12)
                Toggle(localized("presets.auto_start"), isOn: $autoStart)
            } else if mode == .countdown {
                Stepper(localized("presets.countdown_minutes", countdownMinutes), value: $countdownMinutes, in: 1...600)
            }
            Picker(localized("history.subject"), selection: $subject) {
                Text(localized("common.no_subject")).tag(Optional<Subject>.none)
                ForEach(subjects) { Text($0.name).tag(Optional($0)) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(localized("common.cancel")) { dismiss() }
                Spacer()
                Button(localized("common.save"), action: save)
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let preset else { return }
        name = preset.name
        mode = preset.mode
        focusMinutes = preset.focusMinutes
        shortBreakMinutes = preset.shortBreakMinutes
        longBreakMinutes = preset.longBreakMinutes
        roundsPerCycle = preset.roundsPerCycle
        countdownMinutes = preset.countdownMinutes
        autoStart = preset.autoStartNextPhase
        subject = preset.subject
    }

    private func save() {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let preset {
            preset.name = cleanedName
            preset.modeRaw = mode.rawValue
            preset.focusMinutes = focusMinutes
            preset.shortBreakMinutes = shortBreakMinutes
            preset.longBreakMinutes = longBreakMinutes
            preset.roundsPerCycle = roundsPerCycle
            preset.countdownMinutes = countdownMinutes
            preset.autoStartNextPhase = autoStart
            preset.subject = subject
        } else {
            context.insert(TimerPreset(
                name: cleanedName,
                modeRaw: mode.rawValue,
                focusMinutes: focusMinutes,
                shortBreakMinutes: shortBreakMinutes,
                longBreakMinutes: longBreakMinutes,
                roundsPerCycle: roundsPerCycle,
                countdownMinutes: countdownMinutes,
                autoStartNextPhase: autoStart,
                subject: subject
            ))
        }
        try? context.save()
        dismiss()
    }
}
