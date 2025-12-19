import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var personService: PersonServiceProtocol
    private(set) var reviewService: ReviewServiceProtocol

    var people: [Person] = []
    var dueCount: Int = 0
    var searchText: String = ""
    var selectedContext: String?

    init(personService: PersonServiceProtocol, reviewService: ReviewServiceProtocol) {
        self.personService = personService
        self.reviewService = reviewService
    }

    func loadPeople() {
        people = personService.fetchAll(
            searchText: searchText.isEmpty ? nil : searchText,
            context: selectedContext
        )
        dueCount = reviewService.getDueCount()
    }

    func deletePerson(_ person: Person) {
        do {
            try personService.delete(person)
            loadPeople()
        } catch {
            print("Failed to delete person: \(error)")
        }
    }

    var recentContexts: [String] {
        personService.recentContexts()
    }
}
