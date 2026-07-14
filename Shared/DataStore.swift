import Foundation
import SwiftData

enum DataStore {
    private static var schema: Schema {
        Schema([Subject.self, StudySession.self, TimerPreset.self])
    }

    /// Gemeinsamer Speicherort für App und Widget: ein normaler Ordner in
    /// Application Support — kein Group Container, keine System-Rückfrage.
    static var storeDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Lernzeit", isDirectory: true)
    }

    static func makeContainer() -> ModelContainer {
        let fm = FileManager.default
        try? fm.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        let storeURL = storeDirectory.appendingPathComponent("Lernzeit.store")
        migrateLegacyGroupStoreIfNeeded(to: storeURL)
        backupStoreBeforeV3IfNeeded(storeURL: storeURL)
        do {
            return try makeContainer(at: storeURL)
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    /// Öffnet denselben 3.0-Schematyp an einem expliziten Ort. Dieser Seam
    /// erlaubt Migrationstests auf Kopien, ohne den Benutzer-Store anzufassen.
    static func makeContainer(at storeURL: URL) throws -> ModelContainer {
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Erstellt vor dem ersten Öffnen mit dem 3.0-Schema eine einmalige,
    /// vollständige Kopie der SQLite-Dateien. Ein Fehler blockiert den App-Start
    /// nicht; ohne vollständige Kopie wird jedoch kein Marker gesetzt.
    private static func backupStoreBeforeV3IfNeeded(storeURL: URL) {
        let fm = FileManager.default
        let marker = storeDirectory.appendingPathComponent(".v3-backup-done")
        guard !fm.fileExists(atPath: marker.path), fm.fileExists(atPath: storeURL.path) else { return }

        let destination = storeDirectory.appendingPathComponent("Backups/Before-3.0", isDirectory: true)
        do {
            try fm.createDirectory(at: destination, withIntermediateDirectories: true)
            for suffix in ["", "-shm", "-wal"] {
                let source = URL(fileURLWithPath: storeURL.path + suffix)
                guard fm.fileExists(atPath: source.path) else { continue }
                let target = destination.appendingPathComponent(source.lastPathComponent)
                if fm.fileExists(atPath: target.path) { try fm.removeItem(at: target) }
                try fm.copyItem(at: source, to: target)
            }
            fm.createFile(atPath: marker.path, contents: nil)
        } catch {
            try? fm.removeItem(at: destination)
        }
    }

    /// Einmalige Übernahme der v2.0.x-Daten aus dem früheren Group Container.
    /// Läuft dank Markerdatei garantiert nur ein einziges Mal und scheitert
    /// still, falls macOS den Zugriff nicht (mehr) erlaubt — es erscheint
    /// dadurch nie erneut eine Berechtigungs-Abfrage.
    private static func migrateLegacyGroupStoreIfNeeded(to storeURL: URL) {
        let fm = FileManager.default
        let marker = storeDirectory.appendingPathComponent(".legacy-migration-done")
        guard !fm.fileExists(atPath: marker.path) else { return }
        defer { fm.createFile(atPath: marker.path, contents: nil) }
        guard !fm.fileExists(atPath: storeURL.path) else { return }

        let legacyStore = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/group.com.cramleo.Lernzeit/Lernzeit.store")
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: legacyStore.path + suffix)
            let target = URL(fileURLWithPath: storeURL.path + suffix)
            try? fm.copyItem(at: source, to: target)
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

    static func weekTotal(
        sessions: [StudySession],
        subject: Subject? = nil,
        containing date: Date = .now,
        calendar: Calendar = .current
    ) -> TimeInterval {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return 0 }
        return sessions.reduce(0) { total, session in
            guard interval.contains(session.startDate) else { return total }
            if let subject, session.subject !== subject { return total }
            return total + session.duration
        }
    }

    static func presetTotals(sessions: [StudySession]) -> [String: TimeInterval] {
        sessions.reduce(into: [:]) { totals, session in
            let name = session.presetName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            totals[name, default: 0] += session.duration
        }
    }
}
