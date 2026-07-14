import Charts
import SwiftData
import SwiftUI

struct BucketTotal: Identifiable {
    let date: Date
    let minutes: Double
    var id: Date { date }
}

enum StatsRange: String, CaseIterable, Identifiable {
    case twoWeeks
    case twelveWeeks
    case twelveMonths

    var id: String { rawValue }

    var label: String {
        switch self {
        case .twoWeeks: localized("stats.range_two_weeks")
        case .twelveWeeks: localized("stats.range_twelve_weeks")
        case .twelveMonths: localized("stats.range_twelve_months")
        }
    }
}

struct StatsView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @AppStorage(SettingsKeys.dailyGoalMinutes, store: .lernzeitShared) private var dailyGoalMinutes = 120
    @State private var range: StatsRange = .twoWeeks

    private var calendar: Calendar { .current }
    private var dayTotals: [Date: TimeInterval] { Statistics.dayTotals(sessions: sessions) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    StatCard(title: localized("stats.today"), value: formatDuration(todayTotal), icon: "sun.max", tint: .orange)
                    StatCard(title: localized("stats.this_week"), value: formatDuration(weekTotal), icon: "calendar", tint: .blue)
                    StatCard(
                        title: localized("stats.streak"),
                        value: localized(currentStreak == 1 ? "stats.day_count_one" : "stats.day_count_many", currentStreak),
                        icon: "flame.fill",
                        tint: .red
                    )
                }

                goalCard
                weekComparisonCard
                chartCard
                heatmapCard
                recordsCard
                bestHoursCard

                if !subjectTotals.isEmpty {
                    subjectCard
                }
                if !profileTotals.isEmpty {
                    profileCard
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Berechnungen

    private func total(onDayOf date: Date) -> TimeInterval {
        dayTotals[calendar.startOfDay(for: date), default: 0]
    }

    private var todayTotal: TimeInterval { total(onDayOf: .now) }

    private var weekTotal: TimeInterval {
        Statistics.weekTotal(sessions: sessions, containing: .now, calendar: calendar)
    }

    private var previousWeekTotal: TimeInterval {
        let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: .now) ?? .now
        return Statistics.weekTotal(sessions: sessions, containing: previousWeek, calendar: calendar)
    }

    private var currentStreak: Int {
        Statistics.streak(sessions: sessions, goalMinutes: dailyGoalMinutes)
    }

    private var chartData: [BucketTotal] {
        switch range {
        case .twoWeeks:
            return (0..<14).reversed().map { offset in
                let day = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -offset, to: .now)!)
                return BucketTotal(date: day, minutes: dayTotals[day, default: 0] / 60)
            }
        case .twelveWeeks:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)!.start
            return (0..<12).reversed().map { offset in
                let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: weekStart)!
                let minutes = (0..<7).reduce(0.0) { sum, day in
                    let date = calendar.date(byAdding: .day, value: day, to: start)!
                    return sum + dayTotals[calendar.startOfDay(for: date), default: 0] / 60
                }
                return BucketTotal(date: start, minutes: minutes)
            }
        case .twelveMonths:
            let monthStart = calendar.dateInterval(of: .month, for: .now)!.start
            return (0..<12).reversed().map { offset in
                let start = calendar.date(byAdding: .month, value: -offset, to: monthStart)!
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                let minutes = sessions
                    .filter { $0.startDate >= start && $0.startDate < end }
                    .reduce(0.0) { $0 + $1.duration / 60 }
                return BucketTotal(date: start, minutes: minutes)
            }
        }
    }

    private var subjectTotals: [(name: String, color: Color, seconds: TimeInterval)] {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? calendar.startOfDay(for: .now)
        let recent = sessions.filter { $0.startDate >= weekStart }
        var totals: [String: (color: Color, seconds: TimeInterval)] = [:]
        for session in recent {
            let name = session.subject?.name ?? localized("common.no_subject")
            let color = session.subject?.color ?? .gray
            totals[name, default: (color, 0)].seconds += session.duration
        }
        return totals
            .map { (name: $0.key, color: $0.value.color, seconds: $0.value.seconds) }
            .sorted { $0.seconds > $1.seconds }
    }

    private var profileTotals: [(name: String, seconds: TimeInterval)] {
        Statistics.presetTotals(sessions: sessions)
            .map { (name: $0.key, seconds: $0.value) }
            .sorted { $0.seconds > $1.seconds }
    }

    private var hourTotals: [(hour: Int, minutes: Double)] {
        var buckets = [Double](repeating: 0, count: 24)
        for session in sessions {
            buckets[calendar.component(.hour, from: session.startDate)] += session.duration / 60
        }
        return (0..<24).map { (hour: $0, minutes: buckets[$0]) }
    }

    // MARK: - Karten

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(localized("stats.daily_goal"), systemImage: "target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper(localized("duration.minutes", dailyGoalMinutes), value: $dailyGoalMinutes, in: 15...600, step: 15)
                    .font(.callout)
                    .fixedSize()
            }
            ProgressView(value: min(1, todayTotal / TimeInterval(dailyGoalMinutes * 60)))
                .tint(todayTotal >= TimeInterval(dailyGoalMinutes * 60) ? .green : .accentColor)
            Text(localized(
                "stats.goal_progress",
                formatDuration(todayTotal),
                formatDuration(TimeInterval(dailyGoalMinutes * 60))
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var weekComparisonCard: some View {
        let difference = weekTotal - previousWeekTotal
        let symbol = difference > 0 ? "arrow.up.right" : difference < 0 ? "arrow.down.right" : "arrow.right"
        let tint: Color = difference > 0 ? .green : difference < 0 ? .orange : .gray
        return HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(localized("stats.week_comparison"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(localized("stats.week_comparison_value", formatDuration(weekTotal), formatDuration(previousWeekTotal)))
                    .font(.callout.weight(.semibold))
            }
            Spacer()
            Text(localized("stats.week_difference", difference >= 0 ? "+\(formatDuration(abs(difference)))" : "−\(formatDuration(abs(difference)))"))
                .font(.callout.monospacedDigit())
                .foregroundStyle(tint)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(localized("stats.study_time"), systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker(localized("stats.range"), selection: $range) {
                    ForEach(StatsRange.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }

            Chart(chartData) { item in
                BarMark(
                    x: .value(localized("stats.chart_period"), item.date, unit: chartUnit),
                    y: .value(localized("common.minutes"), item.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)

                if range == .twoWeeks {
                    RuleMark(y: .value(localized("settings.goal_section"), Double(dailyGoalMinutes)))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormat)
                }
            }
            .frame(height: 220)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var chartUnit: Calendar.Component {
        switch range {
        case .twoWeeks: .day
        case .twelveWeeks: .weekOfYear
        case .twelveMonths: .month
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch range {
        case .twoWeeks: .dateTime.day().month(.narrow)
        case .twelveWeeks: .dateTime.day().month(.narrow)
        case .twelveMonths: .dateTime.month(.narrow)
        }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(localized("stats.last_six_months"), systemImage: "square.grid.4x3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            HeatmapView(dayTotals: dayTotals, goalSeconds: Double(dailyGoalMinutes) * 60)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var recordsCard: some View {
        let longestSession = sessions.map(\.duration).max() ?? 0
        let bestDay = dayTotals.values.max() ?? 0
        let allTime = sessions.reduce(0) { $0 + $1.duration }
        let bestStreak = Statistics.longestStreak(sessions: sessions, goalMinutes: dailyGoalMinutes)

        return VStack(alignment: .leading, spacing: 14) {
            Label(localized("stats.records"), systemImage: "trophy")
                .font(.caption)
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                GridRow {
                    recordItem(localized("stats.longest_session"), formatDuration(longestSession))
                    recordItem(localized("stats.best_day"), formatDuration(bestDay))
                }
                GridRow {
                    recordItem(
                        localized("stats.longest_streak"),
                        localized(bestStreak == 1 ? "stats.day_count_one" : "stats.day_count_many", bestStreak)
                    )
                    recordItem(localized("stats.total_studied"), formatDuration(allTime))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func recordItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
        }
        .frame(minWidth: 160, alignment: .leading)
    }

    private var bestHoursCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(localized("stats.when_you_study"), systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(hourTotals, id: \.hour) { item in
                BarMark(
                    x: .value(localized("stats.chart_hour"), item.hour),
                    y: .value(localized("common.minutes"), item.minutes)
                )
                .foregroundStyle(Color.accentColor.opacity(0.75))
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(localized("stats.hour_label", hour))
                        }
                    }
                }
            }
            .frame(height: 140)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(localized("stats.study_profiles"), systemImage: "square.stack.3d.up.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            let maximum = profileTotals.first?.seconds ?? 1
            ForEach(profileTotals, id: \.name) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name).font(.callout)
                        Spacer()
                        Text(formatDuration(item.seconds))
                            .font(.callout)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: item.seconds / max(maximum, 1))
                }
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var subjectCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(localized("stats.subjects_this_week"), systemImage: "books.vertical")
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

/// GitHub-Style-Heatmap der letzten 26 Wochen.
struct HeatmapView: View {
    let dayTotals: [Date: TimeInterval]
    let goalSeconds: Double

    private var weeks: [[Date]] {
        let calendar = Calendar.current
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)!.start
        return (0..<26).reversed().map { weekOffset in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: thisWeekStart)!
            return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStart)! }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            ForEach(weeks, id: \.first) { week in
                VStack(spacing: 3) {
                    ForEach(week, id: \.self) { day in
                        cell(for: day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for day: Date) -> some View {
        let isFuture = day > .now
        let seconds = dayTotals[Calendar.current.startOfDay(for: day), default: 0]
        RoundedRectangle(cornerRadius: 2.5)
            .fill(color(seconds: seconds))
            .frame(width: 11, height: 11)
            .opacity(isFuture ? 0 : 1)
            .help(
                isFuture
                    ? ""
                    : localized(
                        "stats.heatmap_help",
                        day.formatted(date: .abbreviated, time: .omitted),
                        formatDuration(seconds)
                    )
            )
    }

    private func color(seconds: TimeInterval) -> Color {
        guard seconds > 0 else { return Color.secondary.opacity(0.12) }
        let fraction = min(1, seconds / max(goalSeconds, 60))
        return Color.accentColor.opacity(0.25 + 0.75 * fraction)
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
