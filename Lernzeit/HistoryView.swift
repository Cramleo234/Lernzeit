import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @Environment(\.modelContext) private var context
    @State private var noteSession: StudySession?
    @State private var editSession: StudySession?

    private var grouped: [(day: Date, items: [StudySession])] {
        let groups = Dictionary(grouping: sessions) {
            Calendar.current.startOfDay(for: $0.startDate)
        }
        return groups.keys.sorted(by: >).map { (day: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        if sessions.isEmpty {
            ContentUnavailableView(
                "Noch keine Sessions",
                systemImage: "clock",
                description: Text("Starte deine erste Lernsession im Timer.")
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
            .sheet(item: $noteSession) { session in
                SessionNoteSheet(session: session)
            }
            .sheet(item: $editSession) { session in
                SessionEditSheet(session: session)
            }
        }
    }

    private func row(for session: StudySession) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(session.subject?.color ?? Color.gray.opacity(0.5))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject?.name ?? "Ohne Fach")
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
            }

            Spacer()

            if session.isPomodoro {
                Text("Pomodoro")
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
            Button("Bearbeiten", systemImage: "slider.horizontal.3") {
                editSession = session
            }
            Button("Notiz bearbeiten", systemImage: "square.and.pencil") {
                noteSession = session
            }
            Button("Löschen", systemImage: "trash", role: .destructive) {
                context.delete(session)
                try? context.save()
            }
        }
        .swipeActions {
            Button("Löschen", systemImage: "trash", role: .destructive) {
                context.delete(session)
                try? context.save()
            }
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Heute" }
        if calendar.isDateInYesterday(day) { return "Gestern" }
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
            Text("Session bearbeiten")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    Text("Fach")
                        .foregroundStyle(.secondary)
                    Menu {
                        Button("Ohne Fach") { session.subject = nil }
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
                            Text(session.subject?.name ?? "Ohne Fach")
                        }
                    }
                    .menuStyle(.button)
                    .fixedSize()
                }
                GridRow {
                    Text("Beginn")
                        .foregroundStyle(.secondary)
                    DatePicker("Beginn", selection: $session.startDate)
                        .labelsHidden()
                }
                GridRow {
                    Text("Dauer")
                        .foregroundStyle(.secondary)
                    Stepper("\(durationMinutes) min", value: $durationMinutes, in: 1...600)
                        .fixedSize()
                }
            }
            .frame(width: 320)

            HStack(spacing: 12) {
                Button("Session löschen", systemImage: "trash", role: .destructive) {
                    context.delete(session)
                    try? context.save()
                    dismiss()
                }

                Spacer()

                Button("Abbrechen") { dismiss() }

                Button("Sichern") {
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
