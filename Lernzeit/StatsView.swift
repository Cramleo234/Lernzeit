import Charts
import SwiftData
import SwiftUI

struct DayTotal: Identifiable {
    let day: Date
    let minutes: Double
    var id: Date { day }
}

struct StatsView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 120

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    StatCard(
                        title: "Heute",
                        value: formatDuration(todayTotal),
                        icon: "sun.max",
                        tint: .orange
                    )
                    StatCard(
                        title: "Diese Woche",
                        value: formatDuration(weekTotal),
                        icon: "calendar",
                        tint: .blue
                    )
                    StatCard(
                        title: "Streak",
                        value: "\(streak) \(streak == 1 ? "Tag" : "Tage")",
                        icon: "flame.fill",
                        tint: .red
                    )
                }

                goalCard
                chartCard

                if !subjectTotals.isEmpty {
                    subjectCard
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Berechnungen

    private func total(onDayOf date: Date) -> TimeInterval {
        let day = calendar.startOfDay(for: date)
        return sessions
            .filter { calendar.startOfDay(for: $0.startDate) == day }
            .reduce(0) { $0 + $1.duration }
    }

    private var todayTotal: TimeInterval { total(onDayOf: .now) }

    private var weekTotal: TimeInterval {
        (0..<7).reduce(0) { sum, offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: .now)!
            return sum + total(onDayOf: day)
        }
    }

    private var streak: Int {
        var totals: [Date: TimeInterval] = [:]
        for session in sessions {
            totals[calendar.startOfDay(for: session.startDate), default: 0] += session.duration
        }
        let goal = TimeInterval(dailyGoalMinutes * 60)
        var count = 0
        var day = calendar.startOfDay(for: .now)
        if totals[day, default: 0] >= goal { count += 1 }
        day = calendar.date(byAdding: .day, value: -1, to: day)!
        while totals[day, default: 0] >= goal {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    private var dayTotals: [DayTotal] {
        (0..<14).reversed().map { offset in
            let day = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -offset, to: .now)!)
            return DayTotal(day: day, minutes: total(onDayOf: day) / 60)
        }
    }

    private var subjectTotals: [(name: String, color: Color, seconds: TimeInterval)] {
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now))!
        let recent = sessions.filter { $0.startDate >= weekAgo }
        var totals: [String: (color: Color, seconds: TimeInterval)] = [:]
        for session in recent {
            let name = session.subject?.name ?? "Ohne Fach"
            let color = session.subject?.color ?? .gray
            totals[name, default: (color, 0)].seconds += session.duration
        }
        return totals
            .map { (name: $0.key, color: $0.value.color, seconds: $0.value.seconds) }
            .sorted { $0.seconds > $1.seconds }
    }

    // MARK: - Karten

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tagesziel", systemImage: "target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper(
                    "\(dailyGoalMinutes) min",
                    value: $dailyGoalMinutes,
                    in: 15...600,
                    step: 15
                )
                .font(.callout)
                .fixedSize()
            }
            ProgressView(value: min(1, todayTotal / TimeInterval(dailyGoalMinutes * 60)))
                .tint(todayTotal >= TimeInterval(dailyGoalMinutes * 60) ? .green : .accentColor)
            Text("\(formatDuration(todayTotal)) von \(formatDuration(TimeInterval(dailyGoalMinutes * 60)))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Letzte 14 Tage", systemImage: "chart.bar")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(dayTotals) { item in
                BarMark(
                    x: .value("Tag", item.day, unit: .day),
                    y: .value("Minuten", item.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)

                RuleMark(y: .value("Ziel", Double(dailyGoalMinutes)))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .frame(height: 220)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var subjectCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Fächer diese Woche", systemImage: "books.vertical")
                .font(.caption)
                .foregroundStyle(.secondary)

            let maxSeconds = subjectTotals.first?.seconds ?? 1
            ForEach(subjectTotals, id: \.name) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(item.color).frame(width: 8, height: 8)
                        Text(item.name).font(.callout)
                        Spacer()
                        Text(formatDuration(item.seconds))
                            .font(.callout)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: item.seconds / max(maxSeconds, 1))
                        .tint(item.color)
                }
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.multicolor)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint == .red ? AnyShapeStyle(tint) : AnyShapeStyle(.primary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
