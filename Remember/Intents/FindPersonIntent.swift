import AppIntents
import SwiftData
import SwiftUI

/// Siri Shortcut: "Hey Siri, who did I meet at..."
struct FindPersonIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Someone"
    static var description = IntentDescription("Search for someone you've saved")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Search", description: "Name, description, or where you met them")
    var query: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Find \(\.$query)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Get search query if not provided
        let searchQuery: String
        if let query = query, !query.isEmpty {
            searchQuery = query
        } else {
            searchQuery = try await $query.requestValue("Who are you looking for?")
        }

        // Search for people
        let results = try await searchPeople(query: searchQuery)

        if results.isEmpty {
            return .result(
                dialog: "I couldn't find anyone matching '\(searchQuery)'",
                view: EmptySearchResultView(query: searchQuery)
            )
        } else if results.count == 1 {
            let person = results[0]
            return .result(
                dialog: "That's \(person.name)",
                view: PersonSearchResultView(person: person)
            )
        } else {
            let names = results.prefix(3).map { $0.name }.joined(separator: ", ")
            return .result(
                dialog: "I found \(results.count) people: \(names)",
                view: MultipleSearchResultsView(people: Array(results.prefix(5)))
            )
        }
    }

    @MainActor
    private func searchPeople(query: String) async throws -> [Person] {
        let container = try ModelContainer(for: Person.self)
        let context = container.mainContext

        let lowercasedQuery = query.lowercased()

        // Fetch all and filter (SwiftData predicate limitations)
        let descriptor = FetchDescriptor<Person>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let allPeople = try context.fetch(descriptor)

        // Filter by name, context, transcript, or keywords
        return allPeople.filter { person in
            if person.name.lowercased().contains(lowercasedQuery) {
                return true
            }
            if let context = person.context?.lowercased(), context.contains(lowercasedQuery) {
                return true
            }
            if let transcript = person.transcriptText?.lowercased(), transcript.contains(lowercasedQuery) {
                return true
            }
            if person.descriptorKeywords.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                return true
            }
            return false
        }
    }
}

// MARK: - Snippet Views

struct PersonSearchResultView: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(person.name.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)

                if let context = person.context {
                    Text(context)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let transcript = person.transcriptText {
                    Text(transcript.prefix(60) + (transcript.count > 60 ? "..." : ""))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct MultipleSearchResultsView: View {
    let people: [Person]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(people) { person in
                HStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .overlay {
                            Text(person.name.prefix(1).uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                    VStack(alignment: .leading) {
                        Text(person.name)
                            .font(.subheadline)
                        if let context = person.context {
                            Text(context)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct EmptySearchResultView: View {
    let query: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.fill.questionmark")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("No one matches '\(query)'")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
