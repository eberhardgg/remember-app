import Foundation
import SwiftData

struct SeedPerson {
    let name: String
    let description: String
    let context: String?
    let categoryName: String?
}

final class SeedDataService {

    static let seedPeople: [SeedPerson] = [
        // Doormen at apartment
        SeedPerson(
            name: "Luis",
            description: "Blue glasses, chin hair",
            context: "Doorman at apartment",
            categoryName: "Doorman"
        ),
        SeedPerson(
            name: "Arturo",
            description: "Older, buzzcut",
            context: "Doorman at apartment",
            categoryName: "Doorman"
        ),
        SeedPerson(
            name: "Gabriel",
            description: "Older, glasses, big teeth",
            context: "Doorman at apartment",
            categoryName: "Doorman"
        ),

        // Neighbors
        SeedPerson(
            name: "Patricia",
            description: "Gym friend Gee",
            context: "Floor 15 neighbor",
            categoryName: "Neighbor"
        ),
        SeedPerson(
            name: "Eric",
            description: "In banking, from Guadalajara",
            context: "Neighbor in building",
            categoryName: "Neighbor"
        ),
        SeedPerson(
            name: "David",
            description: "Tech guy, from Colombia",
            context: "Neighbor in building",
            categoryName: "Neighbor"
        ),
        SeedPerson(
            name: "Hass",
            description: "David's wife, worked at Ikea",
            context: "Neighbor in building",
            categoryName: "Neighbor"
        ),
        SeedPerson(
            name: "Olli",
            description: "Kat's friend, parents are David and Hass, goes to American school",
            context: "Neighbor kid",
            categoryName: "Kid"
        ),

        // Parent friends at Greengates
        SeedPerson(
            name: "Ahmet",
            description: "Arab parent at park",
            context: "Greengates parent friend",
            categoryName: "Parent"
        ),

        // Kat's friends at Greengates
        SeedPerson(
            name: "Lupita",
            description: "7 years old, parents are German",
            context: "Kat's friend at Greengates",
            categoryName: "Kid"
        ),
        SeedPerson(
            name: "Alyssa",
            description: "7 years old",
            context: "Kat's friend at Greengates",
            categoryName: "Kid"
        ),
        SeedPerson(
            name: "Ava",
            description: "7 years old",
            context: "Kat's friend at Greengates",
            categoryName: "Kid"
        ),
        SeedPerson(
            name: "Mila",
            description: "7 years old",
            context: "Kat's friend at Greengates",
            categoryName: "Kid"
        ),
        SeedPerson(
            name: "Nyra",
            description: "7 years old",
            context: "Kat's friend at Greengates",
            categoryName: "Kid"
        ),
        SeedPerson(
            name: "Alexa",
            description: "7 years old",
            context: "Kat's friend at Greengates",
            categoryName: "Kid"
        )
    ]

    static func seedPeople(in context: ModelContext) -> Int {
        // Fetch existing categories
        let categoryDescriptor = FetchDescriptor<PersonCategory>()
        let categories = (try? context.fetch(categoryDescriptor)) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })

        // Check which people already exist (by name)
        let personDescriptor = FetchDescriptor<Person>()
        let existingPeople = (try? context.fetch(personDescriptor)) ?? []
        let existingNames = Set(existingPeople.map { $0.name.lowercased() })

        var addedCount = 0

        for seedPerson in seedPeople {
            // Skip if person already exists
            if existingNames.contains(seedPerson.name.lowercased()) {
                continue
            }

            let person = Person(name: seedPerson.name, context: seedPerson.context)
            person.transcriptText = seedPerson.description

            // Extract keywords from description
            let parser = KeywordParser()
            person.descriptorKeywords = parser.extractKeywords(from: seedPerson.description)

            // Assign category if specified
            if let categoryName = seedPerson.categoryName,
               let category = categoryMap[categoryName] {
                person.category = category
            }

            context.insert(person)
            addedCount += 1
        }

        if addedCount > 0 {
            try? context.save()
        }

        return addedCount
    }
}
