import SwiftUI
import SwiftData

struct PersonEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let person: Person
    let onSave: () -> Void

    @State private var name: String
    @State private var context: String
    @State private var description: String

    init(person: Person, onSave: @escaping () -> Void) {
        self.person = person
        self.onSave = onSave
        _name = State(initialValue: person.name)
        _context = State(initialValue: person.context ?? "")
        _description = State(initialValue: person.transcriptText ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }

                Section("Context") {
                    TextField("Where did you meet?", text: $context)
                }

                Section("Description") {
                    TextField("What do they look like?", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Visual") {
                    Picker("Preferred Visual", selection: Binding(
                        get: { person.preferredVisualType },
                        set: { person.preferredVisualType = $0 }
                    )) {
                        Text("Sketch").tag(VisualType.sketch)
                        Text("Photo").tag(VisualType.photo)
                    }
                    .disabled(person.photoImagePath == nil)

                    if person.photoImagePath == nil {
                        Text("Add a photo to enable this option")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        person.name = name.trimmingCharacters(in: .whitespaces)
        person.context = context.isEmpty ? nil : context
        person.transcriptText = description.isEmpty ? nil : description

        // Re-extract keywords if description changed
        if !description.isEmpty {
            let parser = KeywordParser()
            person.descriptorKeywords = parser.extractKeywords(from: description)
        }

        do {
            try modelContext.save()
            onSave()
            dismiss()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

#Preview {
    PersonEditView(person: Person(name: "Sarah Chen", context: "Tech Conference"), onSave: {})
}
