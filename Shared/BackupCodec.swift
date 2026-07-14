import Foundation

struct BackupSubject: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let weeklyGoalMinutes: Int
    let createdAt: Date
}

struct BackupSession: Codable, Equatable {
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let modeRaw: String
    let note: String
    let presetName: String
    let completedFocusRounds: Int
    let subjectID: UUID?
}

struct BackupPreset: Codable, Equatable {
    let name: String
    let modeRaw: String
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let roundsPerCycle: Int
    let countdownMinutes: Int
    let autoStartNextPhase: Bool
    let createdAt: Date
    let subjectID: UUID?
}

struct LernzeitBackup: Codable, Equatable {
    let formatVersion: Int
    let exportedAt: Date
    let subjects: [BackupSubject]
    let sessions: [BackupSession]
    let presets: [BackupPreset]
}

enum BackupCodecError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedVersion(version):
            "Unsupported Lernzeit backup version: \(version)"
        case let .invalidData(reason):
            "Invalid Lernzeit backup: \(reason)"
        }
    }
}

enum BackupCodec {
    static let currentFormatVersion = 1

    static func encode(_ backup: LernzeitBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> LernzeitBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let backup = try decoder.decode(LernzeitBackup.self, from: data)
        guard backup.formatVersion == currentFormatVersion else {
            throw BackupCodecError.unsupportedVersion(backup.formatVersion)
        }
        try validate(backup)
        return backup
    }

    private static func validate(_ backup: LernzeitBackup) throws {
        let subjectIDs = backup.subjects.map(\.id)
        guard Set(subjectIDs).count == subjectIDs.count else {
            throw BackupCodecError.invalidData("duplicate subject identifiers")
        }
        let knownSubjectIDs = Set(subjectIDs)
        guard backup.subjects.allSatisfy({ subject in
            !subject.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && (0...1_200).contains(subject.weeklyGoalMinutes)
        }) else {
            throw BackupCodecError.invalidData("Subject values are invalid.")
        }

        let validModes = Set(TimerMode.allCases.map(\.rawValue))
        guard backup.sessions.allSatisfy({ session in
            session.duration.isFinite
                && session.duration >= 0
                && session.endDate >= session.startDate
                && (0...1_000_000).contains(session.completedFocusRounds)
                && validModes.contains(session.modeRaw)
                && (session.subjectID.map(knownSubjectIDs.contains) ?? true)
        }) else {
            throw BackupCodecError.invalidData("Session values or references are invalid.")
        }

        guard backup.presets.allSatisfy({ preset in
            !preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && validModes.contains(preset.modeRaw)
                && (5...120).contains(preset.focusMinutes)
                && (1...30).contains(preset.shortBreakMinutes)
                && (5...60).contains(preset.longBreakMinutes)
                && (1...12).contains(preset.roundsPerCycle)
                && (1...600).contains(preset.countdownMinutes)
                && (preset.subjectID.map(knownSubjectIDs.contains) ?? true)
        }) else {
            throw BackupCodecError.invalidData("Study profile values or references are invalid.")
        }
    }

    static func csv(sessions: [BackupSession], subjectNames: [UUID: String]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let header = "start,end,duration_seconds,mode,subject,preset,focus_rounds,note"
        let rows = sessions.map { session in
            [
                formatter.string(from: session.startDate),
                formatter.string(from: session.endDate),
                String(Int(session.duration.rounded())),
                session.modeRaw,
                session.subjectID.flatMap { subjectNames[$0] } ?? "",
                session.presetName,
                String(session.completedFocusRounds),
                session.note,
            ]
            .map(escapeCSVField)
            .joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func escapeCSVField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
