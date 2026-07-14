import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LernzeitDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    let data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct DataManagementView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @Query(sort: \StudySession.startDate) private var sessions: [StudySession]
    @Query(sort: \TimerPreset.createdAt) private var presets: [TimerPreset]
    @State private var exportDocument: LernzeitDataDocument?
    @State private var exportType = UTType.json
    @State private var exportFilename = "Lernzeit-Backup"
    @State private var exporterPresented = false
    @State private var importerPresented = false
    @State private var pendingBackup: LernzeitBackup?
    @State private var importConfirmation = false
    @State private var statusMessage: String?

    var body: some View {
        Section(localized("data.section")) {
            Button(localized("data.export_backup"), systemImage: "archivebox") { prepareBackup() }
            Button(localized("data.export_csv"), systemImage: "tablecells") { prepareCSV() }
            Button(localized("data.import_backup"), systemImage: "square.and.arrow.down") { importerPresented = true }
            Text(localized("data.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let statusMessage {
                Text(statusMessage).font(.caption).foregroundStyle(.secondary)
            }
        }
        .fileExporter(
            isPresented: $exporterPresented,
            document: exportDocument,
            contentType: exportType,
            defaultFilename: exportFilename
        ) { result in
            statusMessage = result.isSuccess ? localized("data.export_success") : localized("data.export_failed")
        }
        .fileImporter(isPresented: $importerPresented, allowedContentTypes: [.json]) { result in
            importFile(result)
        }
        .alert(localized("data.replace_title"), isPresented: $importConfirmation, presenting: pendingBackup) { backup in
            Button(localized("common.cancel"), role: .cancel) { pendingBackup = nil }
            Button(localized("data.replace_action"), role: .destructive) { restore(backup) }
        } message: { backup in
            Text(localized("data.replace_message", backup.subjects.count, backup.sessions.count, backup.presets.count))
        }
    }

    private func prepareBackup() {
        do {
            let backup = BackupService.makeBackup(subjects: subjects, sessions: sessions, presets: presets)
            exportDocument = LernzeitDataDocument(data: try BackupCodec.encode(backup))
            exportType = .json
            exportFilename = "Lernzeit-Backup-\(Date.now.formatted(.iso8601.year().month().day()))"
            exporterPresented = true
        } catch {
            statusMessage = localized("data.export_failed")
        }
    }

    private func prepareCSV() {
        let csv = BackupService.csv(subjects: subjects, sessions: sessions)
        exportDocument = LernzeitDataDocument(data: Data(csv.utf8))
        exportType = .commaSeparatedText
        exportFilename = "Lernzeit-Sitzungen-\(Date.now.formatted(.iso8601.year().month().day()))"
        exporterPresented = true
    }

    private func importFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            pendingBackup = try BackupCodec.decode(Data(contentsOf: url))
            importConfirmation = true
        } catch {
            statusMessage = localized("data.import_failed")
        }
    }

    private func restore(_ backup: LernzeitBackup) {
        do {
            try BackupService.replaceLocalData(with: backup, in: context)
            statusMessage = localized("data.import_success")
            pendingBackup = nil
        } catch {
            statusMessage = localized("data.import_failed")
        }
    }
}

private extension Result where Success == URL, Failure == Error {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
