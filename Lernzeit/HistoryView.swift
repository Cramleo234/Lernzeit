import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @Environment(\.modelContext) private var context

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
