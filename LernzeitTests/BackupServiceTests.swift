import SwiftData
import XCTest
@testable import Lernzeit

@MainActor
final class BackupServiceTests: XCTestCase {
    func testReplacingLocalDataRestoresRelationshipsAndRemovesOldData() throws {
        let sourceSubject = Subject(name: "Physik", colorHex: "#4E7CF6", weeklyGoalMinutes: 180)
        let sourceSession = StudySession(
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_001_800),
            duration: 1_800,
            modeRaw: "pomodoro",
            subject: sourceSubject,
            presetName: "Physik-Zyklus",
            completedFocusRounds: 1
        )
        sourceSession.note = "Kapitel 3"
        let sourcePreset = TimerPreset(
            name: "Physik-Zyklus",
            modeRaw: "pomodoro",
            focusMinutes: 30,
            shortBreakMinutes: 5,
            longBreakMinutes: 15,
            roundsPerCycle: 3,
            subject: sourceSubject
        )
        let backup = BackupService.makeBackup(
            subjects: [sourceSubject],
            sessions: [sourceSession],
            presets: [sourcePreset],
            exportedAt: Date(timeIntervalSince1970: 1_700_002_000)
        )

        let container = try ModelContainer(
            for: Subject.self,
            StudySession.self,
            TimerPreset.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.insert(Subject(name: "Wird ersetzt", colorHex: "#000000"))
        try context.save()

        try BackupService.replaceLocalData(with: backup, in: context)

        let subjects = try context.fetch(FetchDescriptor<Subject>())
        let sessions = try context.fetch(FetchDescriptor<StudySession>())
        let presets = try context.fetch(FetchDescriptor<TimerPreset>())
        XCTAssertEqual(subjects.map(\.name), ["Physik"])
        XCTAssertEqual(subjects.first?.weeklyGoalMinutes, 180)
        XCTAssertEqual(sessions.first?.subject?.name, "Physik")
        XCTAssertEqual(sessions.first?.note, "Kapitel 3")
        XCTAssertEqual(sessions.first?.presetName, "Physik-Zyklus")
        XCTAssertEqual(presets.first?.subject?.name, "Physik")
    }

    func testDecodeRejectsOversizedTimerValues() throws {
        let backup = LernzeitBackup(
            formatVersion: BackupCodec.currentFormatVersion,
            exportedAt: .now,
            subjects: [],
            sessions: [],
            presets: [
                BackupPreset(
                    name: "Ungültig",
                    modeRaw: "pomodoro",
                    focusMinutes: .max,
                    shortBreakMinutes: 5,
                    longBreakMinutes: 20,
                    roundsPerCycle: 4,
                    countdownMinutes: 25,
                    autoStartNextPhase: true,
                    createdAt: .now,
                    subjectID: nil
                )
            ]
        )

        XCTAssertThrowsError(try BackupCodec.decode(BackupCodec.encode(backup)))
    }

    func testDecodeRejectsDanglingSubjectReference() throws {
        let backup = LernzeitBackup(
            formatVersion: BackupCodec.currentFormatVersion,
            exportedAt: .now,
            subjects: [],
            sessions: [
                BackupSession(
                    startDate: Date(timeIntervalSince1970: 10),
                    endDate: Date(timeIntervalSince1970: 20),
                    duration: 10,
                    modeRaw: "stopwatch",
                    note: "",
                    presetName: "",
                    completedFocusRounds: 0,
                    subjectID: UUID()
                )
            ],
            presets: []
        )

        let data = try BackupCodec.encode(backup)
        XCTAssertThrowsError(try BackupCodec.decode(data))
    }
}
