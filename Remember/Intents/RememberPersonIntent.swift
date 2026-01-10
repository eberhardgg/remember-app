import AppIntents
import SwiftData

/// Siri Shortcut: "Hey Siri, remember this person"
struct RememberPersonIntent: AppIntent {
    static var title: LocalizedStringResource = "Remember Someone"
    static var description = IntentDescription("Save a new person you just met")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Name", description: "The person's name")
    var name: String?

    @Parameter(title: "Description", description: "What they look like, where you met them")
    var personDescription: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$name)") {
            \.$personDescription
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Get name if not provided
        let personName: String
        if let name = name, !name.isEmpty {
            personName = name
        } else {
            personName = try await $name.requestValue("What's their name?")
        }

        // Get description if not provided
        let description: String
        if let desc = personDescription, !desc.isEmpty {
            description = desc
        } else {
            description = try await $personDescription.requestValue("Describe \(personName) - what do they look like, where did you meet?")
        }

        // Save the person
        let savedPerson = try await savePerson(name: personName, description: description)

        return .result(
            dialog: "Saved \(savedPerson.name)",
            view: RememberPersonSnippetView(name: savedPerson.name, description: description)
        )
    }

    @MainActor
    private func savePerson(name: String, description: String) async throws -> Person {
        // Get the shared model container
        let container = try ModelContainer(for: Person.self)
        let context = container.mainContext

        // Create person
        let person = Person(name: capitalizedName(name))
        person.transcriptText = description

        // Extract keywords
        let parser = KeywordParser()
        let keywords = parser.extractKeywords(from: description)
        person.descriptorKeywords = keywords

        // Generate sketch in background (don't block Siri response)
        let personId = person.id
        let fileService = FileService()
        let sketchService = SketchService(
            fileService: fileService,
            keywordParser: parser,
            renderer: SketchRenderer()
        )

        // Try to generate sketch
        do {
            let sketchPath = try await sketchService.generateSketch(
                from: description,
                keywords: keywords,
                for: personId
            )
            person.sketchImagePath = sketchPath
        } catch {
            // Continue without sketch - user can regenerate later
        }

        // Save
        context.insert(person)
        try context.save()

        return person
    }

    private func capitalizedName(_ name: String) -> String {
        name.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

/// Snippet view shown in Siri after saving
struct RememberPersonSnippetView: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(name)
                    .font(.headline)
            }

            Text(description.prefix(100) + (description.count > 100 ? "..." : ""))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

import SwiftUI
