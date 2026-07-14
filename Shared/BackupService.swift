import Foundation
import SwiftData

@MainActor
enum BackupService {
    static func makeBackup(
        subjects: [Subject],
        sessions: [StudySession],
        presets: [TimerPreset],
        exportedAt: Date = .now
    ) -> LernzeitBackup {
        var subjectIDs: [ObjectIdentifier: UUID] = [:]
        let backupSubjects = subjects.map { subject in
            let id = UUID()
            subjectIDs[ObjectIdentifier(subject)] = id
            return BackupSubject(
                id: id,
                name: subject.name,
                colorHex: subject.colorHex,
                weeklyGoalMinutes: subject.weeklyGoalMinutes,
                createdAt: subject.createdAt
            )
        }
        let backupSessions = sessions.map { session in
            BackupSession(
                startDate: session.startDate,
                endDate: session.endDate,
                duration: session.duration,
                modeRaw: session.modeRaw,
                note: session.note,
                presetName: session.presetName,
                completedFocusRounds: session.completedFocusRounds,
                subjectID: session.subject.flatMap { subjectIDs[ObjectIdentifier($0)] }
            )
        }
        let backupPresets = presets.map { preset in
            BackupPreset(
                name: preset.name,
                modeRaw: preset.modeRaw,
                focusMinutes: preset.focusMinutes,
                shortBreakMinutes: preset.shortBreakMinutes,
                longBreakMinutes: preset.longBreakMinutes,
                roundsPerCycle: preset.roundsPerCycle,
                countdownMinutes: preset.countdownMinutes,
                autoStartNextPhase: preset.autoStartNextPhase,
                createdAt: preset.createdAt,
                subjectID: preset.subject.flatMap { subjectIDs[ObjectIdentifier($0)] }
            )
        }
        return LernzeitBackup(
            formatVersion: BackupCodec.currentFormatVersion,
            exportedAt: exportedAt,
            subjects: backupSubjects,
            sessions: backupSessions,
            presets: backupPresets
        )
    }

    static func csv(subjects: [Subject], sessions: [StudySession]) -> String {
        let backup = makeBackup(subjects: subjects, sessions: sessions, presets: [])
        let names = Dictionary(uniqueKeysWithValues: backup.subjects.map { ($0.id, $0.name) })
        return BackupCodec.csv(sessions: backup.sessions, subjectNames: names)
    }

    static func replaceLocalData(with backup: LernzeitBackup, in context: ModelContext) throws {
        do {
            try context.fetch(FetchDescriptor<StudySession>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<TimerPreset>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<Subject>()).forEach(context.delete)

            var subjectsByID: [UUID: Subject] = [:]
            for item in backup.subjects {
                let subject = Subject(
                    name: item.name,
                    colorHex: item.colorHex,
                    weeklyGoalMinutes: item.weeklyGoalMinutes
                )
                subject.createdAt = item.createdAt
                context.insert(subject)
                subjectsByID[item.id] = subject
            }
            for item in backup.sessions {
                let session = StudySession(
                    startDate: item.startDate,
                    endDate: item.endDate,
                    duration: item.duration,
                    modeRaw: item.modeRaw,
                    subject: item.subjectID.flatMap { subjectsByID[$0] },
                    presetName: item.presetName,
                    completedFocusRounds: item.completedFocusRounds
                )
                session.note = item.note
                context.insert(session)
            }
            for item in backup.presets {
                let preset = TimerPreset(
                    name: item.name,
                    modeRaw: item.modeRaw,
                    focusMinutes: item.focusMinutes,
                    shortBreakMinutes: item.shortBreakMinutes,
                    longBreakMinutes: item.longBreakMinutes,
                    roundsPerCycle: item.roundsPerCycle,
                    countdownMinutes: item.countdownMinutes,
                    autoStartNextPhase: item.autoStartNextPhase,
                    subject: item.subjectID.flatMap { subjectsByID[$0] }
                )
                preset.createdAt = item.createdAt
                context.insert(preset)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
