import SwiftUI
import SwiftData

struct PersonEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonCategory.sortOrder) private var categories: [PersonCategory]

    let person: Person
    let onSave: () -> Void

    @State private var name: String
    @State private var context: String
    @State private var description: String
    @State private var selectedStyle: IllustrationStyle
    @State private var selectedCategory: PersonCategory?
    @State private var isRegenerating = false
    @State private var isGenerating = false
    @State private var showRegenerateConfirm = false
    @State private var showGenerateConfirm = false

    init(person: Person, onSave: @escaping () -> Void) {
        self.person = person
        self.onSave = onSave
        _name = State(initialValue: person.name)
        _context = State(initialValue: person.context ?? "")
        _description = State(initialValue: person.transcriptText ?? "")
        _selectedStyle = State(initialValue: person.illustrationStyle ?? .current)
        _selectedCategory = State(initialValue: person.category)
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

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as PersonCategory?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.systemImageName)
                                .tag(category as PersonCategory?)
                        }
                    }
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

                // Generate illustration section (for people without sketches)
                if hasAPIKey && person.sketchImagePath == nil && !description.isEmpty {
                    Section {
                        Button {
                            showGenerateConfirm = true
                        } label: {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text("Generate Illustration")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGenerating || description.isEmpty)
                    } footer: {
                        Text("Creates a DALL-E illustration from the description (~$0.04)")
                    }
                }

                // Regenerate illustration section (for people with sketches)
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
            .alert("Generate Illustration?", isPresented: $showGenerateConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Generate") {
                    Task {
                        await generateSketch()
                    }
                }
            } message: {
                Text("This will create a \(selectedStyle.displayName) style illustration using DALL-E (~$0.04).")
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
        person.category = selectedCategory

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

    private func generateSketch() async {
        isGenerating = true

        IllustrationStyle.current = selectedStyle

        let sketchService = SketchService(
            fileService: FileService(),
            keywordParser: KeywordParser(),
            renderer: SketchRenderer()
        )

        do {
            let path = try await sketchService.generateSketch(
                from: description,
                keywords: person.descriptorKeywords,
                for: person.id
            )
            person.sketchImagePath = path
            person.illustrationStyle = selectedStyle

            // Also generate edited description
            let descService = DescriptionService()
            if descService.hasAPIKey {
                let result = try await descService.editDescriptionWithKeywords(
                    rawTranscript: description,
                    keywords: person.descriptorKeywords,
                    personName: person.name
                )
                person.editedDescription = result.description
                person.highlightKeywords = result.keywordsToHighlight
            }

            try? modelContext.save()
        } catch {
            print("Generation failed: \(error)")
        }

        isGenerating = false
    }

    private func regenerateSketch() async {
        isRegenerating = true

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

            // Also regenerate the edited description with keywords
            if !transcript.isEmpty {
                let descService = DescriptionService()
                if descService.hasAPIKey {
                    let result = try await descService.editDescriptionWithKeywords(
                        rawTranscript: transcript,
                        keywords: person.descriptorKeywords,
                        personName: person.name
                    )
                    person.editedDescription = result.description
                    person.highlightKeywords = result.keywordsToHighlight
                }
            }

            try? modelContext.save()
        } catch {
            print("Regeneration failed: \(error)")
        }

        IllustrationStyle.current = previousStyle
        isRegenerating = false
    }
}

#Preview {
    PersonEditView(person: Person(name: "Sarah Chen", context: "Tech Conference"), onSave: {})
        .modelContainer(for: [Person.self, PersonCategory.self], inMemory: true)
}
