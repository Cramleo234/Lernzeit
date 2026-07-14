import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case today
    case timer
    case presets
    case stats
    case history
    case subjects
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: localized("navigation.today")
        case .timer: localized("navigation.timer")
        case .presets: localized("navigation.presets")
        case .stats: localized("navigation.statistics")
        case .history: localized("navigation.history")
        case .subjects: localized("navigation.subjects")
        case .settings: localized("navigation.settings")
        }
    }

    var icon: String {
        switch self {
        case .today: "sun.max.fill"
        case .timer: "timer"
        case .presets: "square.stack.3d.up.fill"
        case .stats: "chart.bar.xaxis"
        case .history: "clock.arrow.circlepath"
        case .subjects: "books.vertical"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var section: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $section) { item in
                Label(item.label, systemImage: item.icon).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            Group {
                switch section ?? .today {
                case .today: TodayView()
                case .timer: TimerView()
                case .presets: PresetsView()
                case .stats: StatsView()
                case .history: HistoryView()
                case .subjects: SubjectsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppBackground() }
            .navigationTitle((section ?? .today).label)
        }
        .frame(minWidth: 820, minHeight: 600)
    }
}
