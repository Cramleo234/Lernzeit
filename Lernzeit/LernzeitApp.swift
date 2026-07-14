import SwiftData
import SwiftUI

@main
struct LernzeitApp: App {
    @State private var engine: TimerEngine
    private let container: ModelContainer

    init() {
        let container = DataStore.makeContainer()
        self.container = container
        let engine = TimerEngine()
        engine.configure(context: container.mainContext)
        _engine = State(initialValue: engine)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(engine)
                .lernzeitAppearance()
        }
        .modelContainer(container)
        .defaultSize(width: 980, height: 660)

        WindowGroup(id: "mini") {
            MiniTimerView()
                .environment(engine)
                .lernzeitAppearance()
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .windowLevel(.floating)

        Settings {
            SettingsView()
                .modelContainer(container)
                .lernzeitAppearance()
        }

        MenuBarExtra {
            MenuBarView()
                .environment(engine)
                .modelContainer(container)
                .lernzeitAppearance()
        } label: {
            if engine.isRunning {
                HStack(spacing: 5) {
                    Image(nsImage: menuBarRingImage(progress: engine.ambientProgress))
                    Text(engine.displayString)
                        .monospacedDigit()
                }
            } else {
                Image(systemName: "graduationcap.fill")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
