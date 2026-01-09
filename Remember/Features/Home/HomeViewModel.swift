import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var personService: PersonServiceProtocol

    var people: [Person] = []
    var searchText: String = ""
    var selectedContext: String?

    init(personService: PersonServiceProtocol) {
        self.personService = personService
    }

    func loadPeople() {
        people = personService.fetchAll(
            searchText: searchText.isEmpty ? nil : searchText,
            context: selectedContext
        )
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
