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
    @State private var selectedStyle: IllustrationStyle
    @State private var isRegenerating = false
    @State private var showRegenerateConfirm = false

    init(person: Person, onSave: @escaping () -> Void) {
        self.person = person
        self.onSave = onSave
        _name = State(initialValue: person.name)
        _context = State(initialValue: person.context ?? "")
        _description = State(initialValue: person.transcriptText ?? "")
        _selectedStyle = State(initialValue: person.illustrationStyle ?? .current)
    }

    private var hasAPIKey: Bool {
        guard let key = UserDefaults.standard.string(forKey: "openai_api_key") else { return false }
        return !key.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }

                Section("Where You Met") {
                    TextField("Coffee shop, work, party...", text: $context)
                }

                Section("Notes") {
                    TextField("Additional details...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                if person.photoImagePath != nil {
                    Section("Display") {
                        Picker("Show", selection: Binding(
                            get: { person.preferredVisualType },
                            set: { person.preferredVisualType = $0 }
                        )) {
                            Text("Illustration").tag(VisualType.sketch)
                            Text("Photo").tag(VisualType.photo)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if hasAPIKey && person.sketchImagePath != nil {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Illustration Style")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(IllustrationStyle.allCases, id: \.self) { style in
                                    Button {
                                        selectedStyle = style
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: style.icon)
                                                .font(.title2)
                                            Text(style.displayName)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedStyle == style ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemBackground))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedStyle == style ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(selectedStyle == style ? .primary : .secondary)
                                }
                            }

                            if selectedStyle != (person.illustrationStyle ?? .current) {
                                Button {
                                    showRegenerateConfirm = true
                                } label: {
                                    HStack {
                                        if isRegenerating {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                        }
                                        Text("Regenerate Illustration")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isRegenerating)
                            }
                        }
                        .padding(.vertical, 4)
                    } footer: {
                        Text("Regenerating costs ~$0.04 via OpenAI")
                            .font(.caption2)
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
            .alert("Regenerate Illustration?", isPresented: $showRegenerateConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Regenerate") {
                    Task {
                        await regenerateSketch()
                    }
                }
            } message: {
                Text("This will create a new \(selectedStyle.displayName) style illustration using DALL-E (~$0.04).")
            }
        }
    }

    private func save() {
        person.name = name.trimmingCharacters(in: .whitespaces)
        person.context = context.isEmpty ? nil : context
        person.transcriptText = description.isEmpty ? nil : description

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

    private func regenerateSketch() async {
        isRegenerating = true

        // Temporarily set the global style to the selected style
        let previousStyle = IllustrationStyle.current
        IllustrationStyle.current = selectedStyle

        let sketchService = SketchService(
            fileService: FileService(),
            keywordParser: KeywordParser(),
            renderer: SketchRenderer()
        )

        do {
            let transcript = person.transcriptText ?? ""
            let path = try await sketchService.regenerateSketch(
                from: transcript.isEmpty ? nil : transcript,
                keywords: person.descriptorKeywords,
                for: person.id
            )
            person.sketchImagePath = path
            person.illustrationStyle = selectedStyle

            // Also regenerate the edited description if we have a transcript
            if !transcript.isEmpty {
                let descService = DescriptionService()
                if descService.hasAPIKey {
                    if let edited = try? await descService.editDescription(
                        rawTranscript: transcript,
                        keywords: person.descriptorKeywords,
                        personName: person.name
                    ) {
                        person.editedDescription = edited
                    }
                }
            }

            try? modelContext.save()
        } catch {
            print("Regeneration failed: \(error)")
        }

        // Restore previous global style
        IllustrationStyle.current = previousStyle
        isRegenerating = false
    }
}

#Preview {
    PersonEditView(person: Person(name: "Sarah Chen", context: "Tech Conference"), onSave: {})
}
