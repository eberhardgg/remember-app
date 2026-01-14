import Foundation
import SwiftData

@Model
final class PersonCategory {
    var id: UUID
    var name: String
    var systemImageName: String
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Person.category)
    var people: [Person] = []

    init(name: String, systemImageName: String = "person.2", sortOrder: Int = 0, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.systemImageName = systemImageName
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }

    static let defaults: [(name: String, icon: String)] = [
        ("Friend", "person.2.fill"),
        ("Colleague", "briefcase.fill"),
        ("Parent", "figure.2.and.child.holdinghands"),
        ("Kid", "figure.child"),
        ("Doorman", "door.left.hand.closed"),
        ("Neighbor", "house.fill")
    ]
}
