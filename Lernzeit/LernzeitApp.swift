import SwiftData
import SwiftUI

@main
struct LernzeitApp: App {
    @State private var engine = TimerEngine()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Subject.self, StudySession.self)
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(engine)
        }
        .modelContainer(container)
        .defaultSize(width: 980, height: 660)

        MenuBarExtra {
            MenuBarView()
                .environment(engine)
                .modelContainer(container)
        } label: {
            if engine.isRunning {
                HStack(spacing: 4) {
                    Image(systemName: engine.mode == .pomodoro && engine.phase == .pause ? "cup.and.saucer.fill" : "timer")
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
