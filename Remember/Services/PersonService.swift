import Foundation
import SwiftData

protocol PersonServiceProtocol {
    func fetchAll(searchText: String?, context: String?) -> [Person]
    func save(_ person: Person) throws
    func delete(_ person: Person) throws
    func recentContexts() -> [String]
}

final class PersonService: PersonServiceProtocol {
    private let modelContext: ModelContext
    private let fileService: FileServiceProtocol

    init(modelContext: ModelContext, fileService: FileServiceProtocol) {
        self.modelContext = modelContext
        self.fileService = fileService
    }

    func fetchAll(searchText: String? = nil, context: String? = nil) -> [Person] {
        var descriptor = FetchDescriptor<Person>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )

        // Build predicate based on filters
        if let searchText = searchText, !searchText.isEmpty {
            let searchPredicate = #Predicate<Person> { person in
                person.name.localizedStandardContains(searchText) ||
                (person.transcriptText?.localizedStandardContains(searchText) ?? false) ||
                (person.context?.localizedStandardContains(searchText) ?? false)
            }
            descriptor.predicate = searchPredicate
        }

        // Note: Compound predicates with optional context filtering
        // would require more complex predicate building

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch people: \(error)")
            return []
        }
    }

    func save(_ person: Person) throws {
        modelContext.insert(person)
        try modelContext.save()
    }

    func delete(_ person: Person) throws {
        // Clean up associated files
        fileService.deleteFiles(for: person)

        // Delete from SwiftData
        modelContext.delete(person)
        try modelContext.save()
    }

    func recentContexts() -> [String] {
        let descriptor = FetchDescriptor<Person>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let people = try modelContext.fetch(descriptor)
            let contexts = people.compactMap { $0.context }
            // Return unique contexts, preserving recency order
            var seen = Set<String>()
            return contexts.filter { seen.insert($0).inserted }
        } catch {
            return []
        }
    }
}
