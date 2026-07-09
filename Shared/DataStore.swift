import Foundation
import SwiftData

enum DataStore {
    /// Container im App-Group-Container, damit auch das Widget lesen kann.
    /// Fällt auf den Standard-Speicherort zurück, wenn die App-Group nicht verfügbar ist.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Subject.self, StudySession.self])
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: LernzeitAppGroup.id
        ) {
            let storeURL = groupURL.appendingPathComponent("Lernzeit.store")
            migrateLegacyStoreIfNeeded(to: storeURL)
            let config = ModelConfiguration(url: storeURL)
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                return container
            }
        }
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    /// Übernimmt einmalig den v1-Store aus Application Support in den App-Group-Container.
    private static func migrateLegacyStoreIfNeeded(to storeURL: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: storeURL.path) else { return }
        let legacyBase = URL.applicationSupportDirectory.appendingPathComponent("default.store")
        guard fm.fileExists(atPath: legacyBase.path) else { return }
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: legacyBase.path + suffix)
            let target = URL(fileURLWithPath: storeURL.path + suffix)
            if fm.fileExists(atPath: source.path) {
                try? fm.copyItem(at: source, to: target)
            }
        }
    }
}

enum Statistics {
    static func dayTotals(sessions: [StudySession], calendar: Calendar = .current) -> [Date: TimeInterval] {
        var totals: [Date: TimeInterval] = [:]
        for session in sessions {
            totals[calendar.startOfDay(for: session.startDate), default: 0] += session.duration
        }
        return totals
    }

    /// Streak = aufeinanderfolgende Tage, an denen das Tagesziel erreicht wurde.
    /// Heute zählt mit, sobald das Ziel erreicht ist; sonst beginnt die Zählung gestern.
    static func streak(sessions: [StudySession], goalMinutes: Int, calendar: Calendar = .current) -> Int {
        let totals = dayTotals(sessions: sessions, calendar: calendar)
        let goal = TimeInterval(max(1, goalMinutes) * 60)
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

    static func longestStreak(sessions: [StudySession], goalMinutes: Int, calendar: Calendar = .current) -> Int {
        let totals = dayTotals(sessions: sessions, calendar: calendar)
        let goal = TimeInterval(max(1, goalMinutes) * 60)
        let reachedDays = totals.filter { $0.value >= goal }.keys.sorted()
        var best = 0
        var current = 0
        var previous: Date?
        for day in reachedDays {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }
}
