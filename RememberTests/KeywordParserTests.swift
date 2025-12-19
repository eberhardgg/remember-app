import XCTest
@testable import Remember

final class KeywordParserTests: XCTestCase {

    var parser: KeywordParser!

    override func setUpWithError() throws {
        parser = KeywordParser()
    }

    override func tearDownWithError() throws {
        parser = nil
    }

    // MARK: - Keyword Extraction Tests

    func test_extractKeywords_findsHairColor() {
        let transcript = "She had beautiful red hair and a warm smile"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.contains("red hair"))
    }

    func test_extractKeywords_findsBrunette() {
        let transcript = "He was a brunette with glasses"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.contains("brunette"))
    }

    func test_extractKeywords_findsGlasses() {
        let transcript = "She wears glasses and has short hair"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.contains("wears glasses") || keywords.contains("glasses"))
    }

    func test_extractKeywords_findsBeard() {
        let transcript = "Tall guy with a beard"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.contains("beard"))
    }

    func test_extractKeywords_findsCurlyHair() {
        let transcript = "She had curly blonde hair"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.contains("curly"))
        XCTAssertTrue(keywords.contains("blonde"))
    }

    func test_extractKeywords_handlesMixedCase() {
        let transcript = "She had BLONDE hair and GLASSES"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.contains("blonde"))
        XCTAssertTrue(keywords.contains("glasses"))
    }

    func test_extractKeywords_returnsEmptyForNoMatches() {
        let transcript = "Really nice person, very friendly"
        let keywords = parser.extractKeywords(from: transcript)

        XCTAssertTrue(keywords.isEmpty)
    }

    // MARK: - Feature Parsing Tests

    func test_parse_extractsHairColor() {
        let keywords = ["red hair", "glasses"]
        let features = parser.parse(keywords)

        XCTAssertEqual(features.hairColor, .red)
    }

    func test_parse_extractsHairStyle() {
        let keywords = ["curly", "brown hair"]
        let features = parser.parse(keywords)

        XCTAssertEqual(features.hairStyle, .curly)
        XCTAssertEqual(features.hairColor, .brown)
    }

    func test_parse_detectsGlasses() {
        let keywords = ["glasses", "short hair"]
        let features = parser.parse(keywords)

        XCTAssertTrue(features.hasGlasses)
    }

    func test_parse_detectsFacialHair() {
        let keywords = ["beard", "dark hair"]
        let features = parser.parse(keywords)

        XCTAssertTrue(features.hasFacialHair)
        XCTAssertEqual(features.facialHairStyle, .beard)
    }

    func test_parse_detectsMustache() {
        let keywords = ["mustache"]
        let features = parser.parse(keywords)

        XCTAssertTrue(features.hasFacialHair)
        XCTAssertEqual(features.facialHairStyle, .mustache)
    }

    func test_parse_detectsBald() {
        let keywords = ["bald"]
        let features = parser.parse(keywords)

        XCTAssertEqual(features.hairStyle, .bald)
    }

    func test_parse_handlesEmptyKeywords() {
        let keywords: [String] = []
        let features = parser.parse(keywords)

        XCTAssertNil(features.hairColor)
        XCTAssertNil(features.hairStyle)
        XCTAssertFalse(features.hasGlasses)
        XCTAssertFalse(features.hasFacialHair)
    }

    func test_parse_handlesMultipleFeatures() {
        let keywords = ["red hair", "curly", "glasses", "goatee"]
        let features = parser.parse(keywords)

        XCTAssertEqual(features.hairColor, .red)
        XCTAssertEqual(features.hairStyle, .curly)
        XCTAssertTrue(features.hasGlasses)
        XCTAssertTrue(features.hasFacialHair)
        XCTAssertEqual(features.facialHairStyle, .goatee)
    }
}
