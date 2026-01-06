import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onComplete: () -> Void

    @State private var name = ""
    @State private var context = ""
    @State private var description = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .font(.title3)
                        .focused($nameFieldFocused)
                }

                Section("Optional") {
                    TextField("Where did you meet?", text: $context)

                    TextField("What do they look like?", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Quick Add")
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
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                nameFieldFocused = true
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let person = Person(name: trimmedName)

        if !context.isEmpty {
            person.context = context
        }

        if !description.isEmpty {
            person.transcriptText = description
            let parser = KeywordParser()
            person.descriptorKeywords = parser.extractKeywords(from: description)
        }

        modelContext.insert(person)
        try? modelContext.save()

        onComplete()
        dismiss()
    }
}

#Preview {
    QuickAddView(onComplete: {})
}
