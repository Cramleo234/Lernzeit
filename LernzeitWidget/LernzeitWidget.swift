import SwiftData
import SwiftUI
import WidgetKit

struct LernzeitEntry: TimelineEntry {
    let date: Date
    let todayMinutes: Int
    let goalMinutes: Int
    let streak: Int
    let last7DaysMinutes: [Double]

    static let sample = LernzeitEntry(
        date: .now,
        todayMinutes: 85,
        goalMinutes: 120,
        streak: 4,
        last7DaysMinutes: [40, 95, 120, 60, 130, 20, 85]
    )
}

struct LernzeitProvider: TimelineProvider {
    func placeholder(in context: Context) -> LernzeitEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (LernzeitEntry) -> Void) {
        completion(context.isPreview ? .sample : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LernzeitEntry>) -> Void) {
        let timeline = Timeline(
            entries: [loadEntry()],
            policy: .after(Date.now.addingTimeInterval(15 * 60))
        )
        completion(timeline)
    }

    private func loadEntry() -> LernzeitEntry {
        let goal = UserDefaults.lernzeitShared.integer(forKey: "dailyGoalMinutes")
        let goalMinutes = goal > 0 ? goal : 120

        let container = DataStore.makeContainer()
        let context = ModelContext(container)
        let sessions = (try? context.fetch(FetchDescriptor<StudySession>())) ?? []

        let calendar = Calendar.current
        let totals = Statistics.dayTotals(sessions: sessions)
        let today = calendar.startOfDay(for: .now)
        let todayMinutes = Int(totals[today, default: 0] / 60)
        let streak = Statistics.streak(sessions: sessions, goalMinutes: goalMinutes)
        let last7 = (0..<7).reversed().map { offset -> Double in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return totals[day, default: 0] / 60
        }

        return LernzeitEntry(
            date: .now,
            todayMinutes: todayMinutes,
            goalMinutes: goalMinutes,
            streak: streak,
            last7DaysMinutes: last7
        )
    }
}

struct LernzeitWidgetEntryView: View {
    var entry: LernzeitEntry
    @Environment(\.widgetFamily) private var family

    private var progress: Double {
        min(1, Double(entry.todayMinutes) / Double(max(1, entry.goalMinutes)))
    }

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress >= 1 ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(entry.todayMinutes)")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Text("von \(entry.goalMinutes) min")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var streakLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
            Text("\(entry.streak) \(entry.streak == 1 ? "Tag" : "Tage")")
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
    }

    private var small: some View {
        VStack(spacing: 8) {
            progressRing
                .frame(maxHeight: .infinity)
            streakLabel
        }
        .padding(4)
    }

    private var medium: some View {
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                progressRing
                    .frame(width: 88, height: 88)
                streakLabel
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Letzte 7 Tage")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                weekBars
            }
        }
        .padding(6)
    }

    private var weekBars: some View {
        let maxMinutes = max(entry.last7DaysMinutes.max() ?? 1, Double(entry.goalMinutes))
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(entry.last7DaysMinutes.enumerated()), id: \.offset) { index, minutes in
                let reached = minutes >= Double(entry.goalMinutes)
                VStack(spacing: 3) {
                    Capsule()
                        .fill(reached ? Color.green : Color.accentColor.opacity(minutes > 0 ? 0.8 : 0.2))
                        .frame(width: 14, height: max(4, 60 * minutes / maxMinutes))
                    Text(weekdayLetter(daysAgo: 6 - index))
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func weekdayLetter(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return String(date.formatted(.dateTime.weekday(.narrow)))
    }
}

struct LernzeitWidget: Widget {
    let kind = "LernzeitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LernzeitProvider()) { entry in
            LernzeitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Lernzeit")
        .description("Tagesfortschritt, Streak und Wochenübersicht auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LernzeitWidgetBundle: WidgetBundle {
    var body: some Widget {
        LernzeitWidget()
    }
}
