import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonCategory.sortOrder) private var categories: [PersonCategory]

    let onComplete: () -> Void

    @State private var name = ""
    @State private var context = ""
    @State private var description = ""
    @State private var selectedCategory: PersonCategory?
    @State private var shouldGenerateSketch = true
    @State private var isGeneratingSketch = false
    @FocusState private var nameFieldFocused: Bool

    private var hasAPIKey: Bool {
        UserDefaults.standard.string(forKey: "openai_api_key") != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .font(.title3)
                        .focused($nameFieldFocused)

                    TextField("Where did you meet?", text: $context)

                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as PersonCategory?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.systemImageName)
                                .tag(category as PersonCategory?)
                        }
                    }
                }

                Section {
                    TextField("What do they look like?", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    if hasAPIKey && !description.isEmpty {
                        Toggle("Generate illustration", isOn: $shouldGenerateSketch)
                    }
                } footer: {
                    if hasAPIKey && !description.isEmpty && shouldGenerateSketch {
                        Text("AI illustration costs ~$0.04")
                    }
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGeneratingSketch)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isGeneratingSketch {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .onAppear {
                nameFieldFocused = true
            }
            .interactiveDismissDisabled(isGeneratingSketch)
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let person = Person(name: trimmedName)

        if !context.isEmpty {
            person.context = context
        }

        person.category = selectedCategory

        if !description.isEmpty {
            person.transcriptText = description
            let parser = KeywordParser()
            person.descriptorKeywords = parser.extractKeywords(from: description)

            if shouldGenerateSketch && hasAPIKey {
                isGeneratingSketch = true
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
                    person.illustrationStyle = IllustrationStyle.current
                } catch {
                    print("Failed to generate sketch: \(error)")
                }
                isGeneratingSketch = false
            }
        }

        modelContext.insert(person)
        try? modelContext.save()

        onComplete()
        dismiss()
    }
}

#Preview {
    QuickAddView(onComplete: {})
        .modelContainer(for: [Person.self, PersonCategory.self], inMemory: true)
}
