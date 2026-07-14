import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @Environment(\.modelContext) private var context
    @State private var noteSession: StudySession?
    @State private var editSession: StudySession?
    @State private var searchText = ""

    private var filteredSessions: [StudySession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sessions }
        return sessions.filter { session in
            [session.subject?.name, session.note, session.presetName, session.modeRaw]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    private var grouped: [(day: Date, items: [StudySession])] {
        let groups = Dictionary(grouping: filteredSessions) {
            Calendar.current.startOfDay(for: $0.startDate)
        }
        return groups.keys.sorted(by: >).map { (day: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    localized("history.empty_title"),
                    systemImage: "clock",
                    description: Text(localized("history.empty_description"))
                )
            } else if filteredSessions.isEmpty {
                ContentUnavailableView(
                    localized("history.no_results_title"),
                    systemImage: "magnifyingglass",
                    description: Text(localized("history.no_results_description", searchText))
                )
            } else {
                List {
                    ForEach(grouped, id: \.day) { group in
                        Section {
                            ForEach(group.items) { session in
                                row(for: session)
                            }
                        } header: {
                            HStack {
                                Text(dayLabel(group.day))
                                Spacer()
                                Text(formatDuration(group.items.reduce(0) { $0 + $1.duration }))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .searchable(text: $searchText, prompt: localized("history.search_prompt"))
        .sheet(item: $noteSession) { session in
            SessionNoteSheet(session: session)
        }
        .sheet(item: $editSession) { session in
            SessionEditSheet(session: session)
        }
    }

    private func row(for session: StudySession) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(session.subject?.color ?? Color.gray.opacity(0.5))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject?.name ?? localized("common.no_subject"))
                Text("\(session.startDate.formatted(date: .omitted, time: .shortened)) – \(session.endDate.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if !session.presetName.isEmpty {
                    Label(
                        session.completedFocusRounds > 0
                            ? localized("history.profile_with_rounds", session.presetName, session.completedFocusRounds)
                            : localized("history.profile", session.presetName),
                        systemImage: "square.stack.3d.up"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if session.isPomodoro || session.isCountdown {
                Text(session.isCountdown ? localized("timer.mode.countdown") : localized("timer.mode.pomodoro"))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15), in: .capsule)
            }

            Text(formatDuration(session.duration))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(localized("history.edit"), systemImage: "slider.horizontal.3") {
                editSession = session
            }
            Button(localized("history.edit_note"), systemImage: "square.and.pencil") {
                noteSession = session
            }
            Button(localized("common.delete"), systemImage: "trash", role: .destructive) {
                context.delete(session)
                try? context.save()
            }
        }
        .swipeActions {
            Button(localized("common.delete"), systemImage: "trash", role: .destructive) {
                context.delete(session)
                try? context.save()
            }
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return localized("history.today") }
        if calendar.isDateInYesterday(day) { return localized("history.yesterday") }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

/// Nachträgliches Korrigieren einer Session — etwa wenn der Timer
/// aus Versehen lief und die Statistik verfälschen würde.
struct SessionEditSheet: View {
    @Bindable var session: StudySession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @State private var durationMinutes = 1

    var body: some View {
        VStack(spacing: 18) {
            Text(localized("history.edit_session"))
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    Text(localized("history.subject"))
                        .foregroundStyle(.secondary)
                    Menu {
                        Button(localized("common.no_subject")) { session.subject = nil }
                        if !subjects.isEmpty {
                            Divider()
                            ForEach(subjects) { subject in
                                Button(subject.name) { session.subject = subject }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(session.subject?.color ?? Color.secondary.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(session.subject?.name ?? localized("common.no_subject"))
                        }
                    }
                    .menuStyle(.button)
                    .fixedSize()
                }
                GridRow {
                    Text(localized("history.start"))
                        .foregroundStyle(.secondary)
                    DatePicker(localized("history.start"), selection: $session.startDate)
                        .labelsHidden()
                }
                GridRow {
                    Text(localized("history.duration"))
                        .foregroundStyle(.secondary)
                    Stepper(localized("duration.minutes", durationMinutes), value: $durationMinutes, in: 1...600)
                        .fixedSize()
                }
            }
            .frame(width: 320)

            HStack(spacing: 12) {
                Button(localized("history.delete_session"), systemImage: "trash", role: .destructive) {
                    context.delete(session)
                    try? context.save()
                    dismiss()
                }

                Spacer()

                Button(localized("common.cancel")) { dismiss() }

                Button(localized("common.save")) {
                    session.duration = TimeInterval(durationMinutes * 60)
                    session.endDate = session.startDate.addingTimeInterval(session.duration)
                    try? context.save()
                    dismiss()
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
            }
            .frame(width: 320)
        }
        .padding(28)
        .onAppear {
            durationMinutes = max(1, Int(session.duration / 60))
        }
    }
}
