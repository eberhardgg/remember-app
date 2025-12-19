import XCTest
@testable import Remember

final class DateExtensionTests: XCTestCase {

    func test_relativeDescription_today() {
        let date = Date()
        XCTAssertEqual(date.relativeDescription, "Today")
    }

    func test_relativeDescription_tomorrow() {
        let date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(date.relativeDescription, "Tomorrow")
    }

    func test_relativeDescription_yesterday() {
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(date.relativeDescription, "Yesterday")
    }

    func test_relativeDescription_futureDays() {
        let date = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        XCTAssertEqual(date.relativeDescription, "In 5 days")
    }

    func test_relativeDescription_futureSingular() {
        let date = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        // Note: 2 days is plural
        XCTAssertEqual(date.relativeDescription, "In 2 days")
    }

    func test_relativeDescription_pastDays() {
        let date = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        XCTAssertEqual(date.relativeDescription, "3 days ago")
    }

    func test_relativeDescription_pastSingular() {
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertEqual(date.relativeDescription, "2 days ago")
    }
}
