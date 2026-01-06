import XCTest
import SwiftData
@testable import Remember

@MainActor
final class ReviewServiceTests: XCTestCase {

    var container: ModelContainer!
    var modelContext: ModelContext!
    var reviewService: ReviewService!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Person.self, configurations: config)
        modelContext = container.mainContext
        reviewService = ReviewService(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        container = nil
        modelContext = nil
        reviewService = nil
    }

    // MARK: - Spaced Repetition Algorithm Tests

    func test_updateReviewState_withGotIt_increasesInterval() throws {
        // Arrange
        let person = Person(name: "Test Person")
        person.intervalDays = 1
        person.easeFactor = 2.5
        modelContext.insert(person)
        try modelContext.save()

        // Act
        reviewService.updateReviewState(for: person, gotIt: true)

        // Assert
        XCTAssertEqual(person.intervalDays, 3) // 1 * 2.5 = 2.5, rounded to 3
        XCTAssertEqual(person.easeFactor, 2.6, accuracy: 0.01)
        XCTAssertNotNil(person.lastReviewedAt)
    }

    func test_updateReviewState_withGotIt_capsEaseFactorAt3() throws {
        // Arrange
        let person = Person(name: "Test Person")
        person.intervalDays = 10
        person.easeFactor = 2.95
        modelContext.insert(person)
        try modelContext.save()

        // Act
        reviewService.updateReviewState(for: person, gotIt: true)

        // Assert
        XCTAssertEqual(person.easeFactor, 3.0, accuracy: 0.01)
    }

    func test_updateReviewState_withMissed_resetsInterval() throws {
        // Arrange
        let person = Person(name: "Test Person")
        person.intervalDays = 10
        person.easeFactor = 2.5
        modelContext.insert(person)
        try modelContext.save()

        // Act
        reviewService.updateReviewState(for: person, gotIt: false)

        // Assert
        XCTAssertEqual(person.intervalDays, 1)
        XCTAssertEqual(person.easeFactor, 2.3, accuracy: 0.01)
    }

    func test_updateReviewState_withMissed_floorsEaseFactorAt1_3() throws {
        // Arrange
        let person = Person(name: "Test Person")
        person.intervalDays = 5
        person.easeFactor = 1.4
        modelContext.insert(person)
        try modelContext.save()

        // Act
        reviewService.updateReviewState(for: person, gotIt: false)

        // Assert
        XCTAssertEqual(person.easeFactor, 1.3, accuracy: 0.01)
    }

    func test_updateReviewState_setsNextDueDate() throws {
        // Arrange
        let person = Person(name: "Test Person")
        person.intervalDays = 1
        person.easeFactor = 2.5
        modelContext.insert(person)
        try modelContext.save()

        let beforeUpdate = Date()

        // Act
        reviewService.updateReviewState(for: person, gotIt: true)

        // Assert
        // New interval should be ~3 days, so nextDueAt should be ~3 days from now
        let expectedDueDate = Calendar.current.date(byAdding: .day, value: 3, to: beforeUpdate)!
        let tolerance: TimeInterval = 60 // 1 minute tolerance
        XCTAssertEqual(
            person.nextDueAt.timeIntervalSince1970,
            expectedDueDate.timeIntervalSince1970,
            accuracy: tolerance
        )
    }

    // MARK: - Queue Tests

    func test_getDueCount_returnsCorrectCount() throws {
        // Arrange
        let duePerson1 = Person(name: "Due 1")
        duePerson1.nextDueAt = Date().addingTimeInterval(-86400) // Yesterday

        let duePerson2 = Person(name: "Due 2")
        duePerson2.nextDueAt = Date().addingTimeInterval(-3600) // 1 hour ago

        let futurePerson = Person(name: "Future")
        futurePerson.nextDueAt = Date().addingTimeInterval(86400) // Tomorrow

        modelContext.insert(duePerson1)
        modelContext.insert(duePerson2)
        modelContext.insert(futurePerson)
        try modelContext.save()

        // Act
        let count = reviewService.getDueCount()

        // Assert
        XCTAssertEqual(count, 2)
    }

    func test_getReviewQueue_returnsDueItemsFirst() throws {
        // Arrange
        let duePerson = Person(name: "Due Person")
        duePerson.nextDueAt = Date().addingTimeInterval(-86400) // Yesterday

        let nearDuePerson = Person(name: "Near Due")
        nearDuePerson.nextDueAt = Date().addingTimeInterval(86400) // Tomorrow

        let farPerson = Person(name: "Far Future")
        farPerson.nextDueAt = Date().addingTimeInterval(86400 * 10) // 10 days

        modelContext.insert(duePerson)
        modelContext.insert(nearDuePerson)
        modelContext.insert(farPerson)
        try modelContext.save()

        // Act
        let queue = reviewService.getReviewQueue(limit: 5)

        // Assert
        XCTAssertEqual(queue.count, 2) // Due + near-due, but not far future
        XCTAssertEqual(queue.first?.name, "Due Person")
    }

    func test_getReviewQueue_respectsLimit() throws {
        // Arrange
        for i in 0..<10 {
            let person = Person(name: "Person \(i)")
            person.nextDueAt = Date().addingTimeInterval(-Double(i) * 3600)
            modelContext.insert(person)
        }
        try modelContext.save()

        // Act
        let queue = reviewService.getReviewQueue(limit: 3)

        // Assert
        XCTAssertEqual(queue.count, 3)
    }
}
