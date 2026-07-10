import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case timer
    case stats
    case history
    case subjects
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .timer: localized("navigation.timer")
        case .stats: localized("navigation.statistics")
        case .history: localized("navigation.history")
        case .subjects: localized("navigation.subjects")
        case .settings: localized("navigation.settings")
        }
    }

    var icon: String {
        switch self {
        case .timer: "timer"
        case .stats: "chart.bar.xaxis"
        case .history: "clock.arrow.circlepath"
        case .subjects: "books.vertical"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var section: AppSection? = .timer

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $section) { item in
                Label(item.label, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            Group {
                switch section ?? .timer {
                case .timer: TimerView()
                case .stats: StatsView()
                case .history: HistoryView()
                case .subjects: SubjectsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppBackground() }
            .navigationTitle((section ?? .timer).label)
        }
    }
}
