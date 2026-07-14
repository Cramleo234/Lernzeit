import XCTest
@testable import Lernzeit

final class BackupCodecTests: XCTestCase {
    func testJSONRoundTripPreservesSubjectsSessionsAndPresets() throws {
        let subjectID = UUID()
        let backup = LernzeitBackup(
            formatVersion: 1,
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            subjects: [
                .init(id: subjectID, name: "Mathematik", colorHex: "#4E7CF6", weeklyGoalMinutes: 180, createdAt: Date(timeIntervalSince1970: 100))
            ],
            sessions: [
                .init(
                    startDate: Date(timeIntervalSince1970: 200),
                    endDate: Date(timeIntervalSince1970: 3_200),
                    duration: 3_000,
                    modeRaw: "pomodoro",
                    note: "Kapitel 1, \"Ableitungen\"",
                    presetName: "Mathe intensiv",
                    completedFocusRounds: 2,
                    subjectID: subjectID
                )
            ],
            presets: [
                .init(
                    name: "Mathe intensiv",
                    modeRaw: "pomodoro",
                    focusMinutes: 50,
                    shortBreakMinutes: 10,
                    longBreakMinutes: 25,
                    roundsPerCycle: 4,
                    countdownMinutes: 25,
                    autoStartNextPhase: true,
                    createdAt: Date(timeIntervalSince1970: 150),
                    subjectID: subjectID
                )
            ]
        )

        let data = try BackupCodec.encode(backup)
        let decoded = try BackupCodec.decode(data)

        XCTAssertEqual(decoded, backup)
    }

    func testCSVQuotesCommasQuotesAndLineBreaks() {
        let session = BackupSession(
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 60),
            duration: 60,
            modeRaw: "stopwatch",
            note: "Zeile 1, \"wichtig\"\nZeile 2",
            presetName: "",
            completedFocusRounds: 0,
            subjectID: nil
        )

        let csv = BackupCodec.csv(sessions: [session], subjectNames: [:])

        XCTAssertTrue(csv.hasPrefix("start,end,duration_seconds,mode,subject,preset,focus_rounds,note\n"))
        XCTAssertTrue(csv.contains("\"Zeile 1, \"\"wichtig\"\"\nZeile 2\""))
    }
}
