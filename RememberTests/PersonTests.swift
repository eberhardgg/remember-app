import XCTest
import SwiftData
@testable import Remember

final class PersonTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_setsDefaults() {
        let person = Person(name: "Test Person")

        XCTAssertEqual(person.name, "Test Person")
        XCTAssertNil(person.context)
        XCTAssertEqual(person.easeFactor, 2.5)
        XCTAssertEqual(person.intervalDays, 1)
        XCTAssertEqual(person.preferredVisualType, .sketch)
        XCTAssertTrue(person.descriptorKeywords.isEmpty)
    }

    func test_init_withContext() {
        let person = Person(name: "Test Person", context: "Work")

        XCTAssertEqual(person.context, "Work")
    }

    // MARK: - Due Status Tests

    func test_isDue_returnsTrueWhenPastDue() {
        let person = Person(name: "Test")
        person.nextDueAt = Date().addingTimeInterval(-3600) // 1 hour ago

        XCTAssertTrue(person.isDue)
    }

    func test_isDue_returnsTrueWhenDueNow() {
        let person = Person(name: "Test")
        person.nextDueAt = Date()

        XCTAssertTrue(person.isDue)
    }

    func test_isDue_returnsFalseWhenFuture() {
        let person = Person(name: "Test")
        person.nextDueAt = Date().addingTimeInterval(3600) // 1 hour from now

        XCTAssertFalse(person.isDue)
    }

    // MARK: - Days Until Due Tests

    func test_daysUntilDue_returnsPositiveForFuture() {
        let person = Person(name: "Test")
        person.nextDueAt = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        XCTAssertEqual(person.daysUntilDue, 3)
    }

    func test_daysUntilDue_returnsNegativeForPast() {
        let person = Person(name: "Test")
        person.nextDueAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        XCTAssertEqual(person.daysUntilDue, -2)
    }

    func test_daysUntilDue_returnsZeroForToday() {
        let person = Person(name: "Test")
        person.nextDueAt = Date()

        XCTAssertEqual(person.daysUntilDue, 0)
    }

    // MARK: - Visual URL Tests

    func test_preferredVisualURL_returnsSketchPath() {
        let person = Person(name: "Test")
        person.sketchImagePath = "sketches/test.png"
        person.preferredVisualType = .sketch

        let url = person.preferredVisualURL

        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains("sketches/test.png") ?? false)
    }

    func test_preferredVisualURL_returnsPhotoPath() {
        let person = Person(name: "Test")
        person.photoImagePath = "photos/test.jpg"
        person.preferredVisualType = .photo

        let url = person.preferredVisualURL

        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains("photos/test.jpg") ?? false)
    }

    func test_preferredVisualURL_returnsNilWhenNoPath() {
        let person = Person(name: "Test")
        person.preferredVisualType = .sketch
        // sketchImagePath is nil

        XCTAssertNil(person.preferredVisualURL)
    }
}
