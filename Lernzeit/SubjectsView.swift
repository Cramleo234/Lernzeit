import SwiftData
import SwiftUI

struct SubjectsView: View {
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @Environment(\.modelContext) private var context
    @State private var newName = ""
    @State private var selectedColor = SubjectsView.palette[0]

    static let palette = [
        "#4E7CF6", "#A06CF5", "#F56CA9", "#F5726C",
        "#F5A25C", "#E8C64E", "#5CC98A", "#4EC6C6",
    ]

    var body: some View {
        VStack(spacing: 20) {
            addBar

            if subjects.isEmpty {
                ContentUnavailableView(
                    localized("subjects.empty_title"),
                    systemImage: "books.vertical",
                    description: Text(localized("subjects.empty_description"))
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(subjects) { subject in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(subject.color)
                                .frame(width: 12, height: 12)
                            Text(subject.name)
                            Spacer()
                            Text(formatDuration(subject.sessions.reduce(0) { $0 + $1.duration }))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text(localized(
                                subject.sessions.count == 1 ? "subjects.session_count_one" : "subjects.session_count_many",
                                subject.sessions.count
                            ))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(localized("common.delete"), systemImage: "trash", role: .destructive) {
                                context.delete(subject)
                                try? context.save()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.top, 20)
    }

    private var addBar: some View {
        HStack(spacing: 12) {
            TextField(localized("subjects.new_placeholder"), text: $newName)
                .textFieldStyle(.plain)
                .frame(minWidth: 160)
                .onSubmit(addSubject)

            HStack(spacing: 6) {
                ForEach(SubjectsView.palette, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 16, height: 16)
                        .overlay {
                            if hex == selectedColor {
                                Circle().strokeBorder(.primary, lineWidth: 2)
                            }
                        }
                        .onTapGesture { selectedColor = hex }
                }
            }

            Button(localized("subjects.add"), systemImage: "plus", action: addSubject)
                .buttonStyle(.glassProminent)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private func addSubject() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(Subject(name: name, colorHex: selectedColor))
        try? context.save()
        newName = ""
    }
}
