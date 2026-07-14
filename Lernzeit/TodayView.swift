import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(TimerEngine.self) private var engine
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @Query(sort: \TimerPreset.createdAt) private var presets: [TimerPreset]
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @AppStorage(SettingsKeys.dailyGoalMinutes, store: .lernzeitShared) private var dailyGoalMinutes = 120

    private var calendar: Calendar { .current }
    private var todayStart: Date { calendar.startOfDay(for: .now) }
    private var weekStart: Date { calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? todayStart }
    private var todayTotal: TimeInterval { sessions.filter { $0.startDate >= todayStart }.reduce(0) { $0 + $1.duration } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if engine.isRunning { activeTimerCard }
                goalCard
                profileCard
                if subjects.contains(where: { $0.weeklyGoalMinutes > 0 }) { subjectGoalsCard }
                if let latest = sessions.first { latestCard(latest) }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localized("today.title"))
                .font(.largeTitle.weight(.semibold))
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .foregroundStyle(.secondary)
        }
    }

    private var activeTimerCard: some View {
        HStack(spacing: 16) {
            Image(systemName: engine.phase.isBreak ? "cup.and.saucer.fill" : "brain.head.profile.fill")
                .font(.largeTitle)
                .foregroundStyle(engine.ambientColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(localized("today.active_session")).font(.caption).foregroundStyle(.secondary)
                Text(engine.displayString).font(.title.monospacedDigit())
                Text(engine.mode == .pomodoro ? engine.phase.label : engine.mode.label)
            }
            Spacer()
            Button(engine.isPaused ? localized("common.resume") : localized("common.pause")) {
                engine.isPaused ? engine.resume() : engine.pause()
            }
            .buttonStyle(.glass)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(localized("today.daily_progress"), systemImage: "target")
                Spacer()
                Text("\(formatDuration(todayTotal)) / \(formatDuration(TimeInterval(dailyGoalMinutes * 60)))")
                    .monospacedDigit().foregroundStyle(.secondary)
            }
            ProgressView(value: min(1, todayTotal / max(60, TimeInterval(dailyGoalMinutes * 60))))
                .tint(todayTotal >= TimeInterval(dailyGoalMinutes * 60) ? .green : .accentColor)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(localized("today.quick_start"), systemImage: "bolt.fill")
                .font(.headline)
            if presets.isEmpty {
                Text(localized("today.no_presets"))
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 12) {
                    ForEach(Array(presets.prefix(6))) { preset in
                        quickStartButton(for: preset)
                    }
                }
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func quickStartButton(for preset: TimerPreset) -> some View {
        Button {
            engine.apply(preset)
            engine.start()
        } label: {
            HStack {
                Circle()
                    .fill(preset.subject?.color ?? .accentColor)
                    .frame(width: 9, height: 9)
                VStack(alignment: .leading) {
                    Text(preset.name).font(.headline)
                    Text(preset.mode.label).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.fill")
            }
            .padding(12)
            .contentShape(.rect)
        }
        .buttonStyle(.glass)
        .disabled(engine.isRunning)
        .accessibilityHint(localized("today.start_preset_hint", preset.name))
    }

    private var subjectGoalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(localized("today.weekly_subject_goals"), systemImage: "books.vertical.fill")
                .font(.headline)
            ForEach(subjects.filter { $0.weeklyGoalMinutes > 0 }) { subject in
                let total = sessions.filter { $0.startDate >= weekStart && $0.subject === subject }.reduce(0) { $0 + $1.duration }
                let goal = TimeInterval(subject.weeklyGoalMinutes * 60)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Circle().fill(subject.color).frame(width: 8, height: 8)
                        Text(subject.name)
                        Spacer()
                        Text("\(formatDuration(total)) / \(formatDuration(goal))")
                            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    }
                    ProgressView(value: min(1, total / max(60, goal))).tint(subject.color)
                }
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func latestCard(_ session: StudySession) -> some View {
        HStack {
            Label(localized("today.last_session"), systemImage: "clock.arrow.circlepath")
            Spacer()
            VStack(alignment: .trailing) {
                Text(session.subject?.name ?? localized("common.no_subject"))
                Text(formatDuration(session.duration)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
