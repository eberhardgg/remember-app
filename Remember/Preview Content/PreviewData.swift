import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let samplePeople: [Person] = [
        {
            let p = Person(name: "Sarah Chen", context: "Tech Conference")
            p.transcriptText = "She had short dark hair and wore glasses. Very friendly, talked about machine learning."
            return p
        }(),
        {
            let p = Person(name: "Mike Johnson", context: "Neighbor")
            p.transcriptText = "Tall guy with a beard, usually wears a baseball cap."
            return p
        }(),
        {
            let p = Person(name: "Emma Williams", context: "Book Club")
            p.transcriptText = "Curly red hair, always carries a tote bag with books."
            return p
        }()
    ]

    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Person.self, configurations: config)

        for person in samplePeople {
            container.mainContext.insert(person)
        }

        return container
    }
}
