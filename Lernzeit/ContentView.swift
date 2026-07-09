import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case timer = "Timer"
    case stats = "Statistik"
    case history = "Verlauf"
    case subjects = "Fächer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timer: "timer"
        case .stats: "chart.bar.xaxis"
        case .history: "clock.arrow.circlepath"
        case .subjects: "books.vertical"
        }
    }
}

struct ContentView: View {
    @State private var section: AppSection? = .timer

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.icon)
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
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppBackground() }
            .navigationTitle((section ?? .timer).rawValue)
            .toolbar {
                ToolbarItem {
                    SettingsLink {
                        Image(systemName: "gearshape")
                    }
                    .help("Einstellungen öffnen")
                }
            }
        }
    }
}
