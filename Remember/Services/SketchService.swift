import Foundation
import UIKit

enum SketchServiceError: LocalizedError {
    case generationFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Couldn't create the sketch. Please try again."
        case .saveFailed:
            return "Couldn't save the sketch."
        }
    }
}

protocol SketchServiceProtocol {
    func generateSketch(from keywords: [String], for personId: UUID) async throws -> String
    func regenerateSketch(from keywords: [String], for personId: UUID, variant: Int) async throws -> String
}

final class SketchService: SketchServiceProtocol {
    private let fileService: FileServiceProtocol
    private let keywordParser: KeywordParserProtocol
    private let renderer: SketchRendererProtocol

    init(
        fileService: FileServiceProtocol,
        keywordParser: KeywordParserProtocol,
        renderer: SketchRendererProtocol
    ) {
        self.fileService = fileService
        self.keywordParser = keywordParser
        self.renderer = renderer
    }

    func generateSketch(from keywords: [String], for personId: UUID) async throws -> String {
        try await generateSketch(from: keywords, for: personId, variant: 0)
    }

    func regenerateSketch(from keywords: [String], for personId: UUID, variant: Int) async throws -> String {
        try await generateSketch(from: keywords, for: personId, variant: variant)
    }

    private func generateSketch(from keywords: [String], for personId: UUID, variant: Int) async throws -> String {
        // Parse keywords into structured features
        let features = keywordParser.parse(keywords)

        // Render the sketch
        guard let image = renderer.render(features: features, variant: variant) else {
            throw SketchServiceError.generationFailed
        }

        // Convert to PNG data
        guard let data = image.pngData() else {
            throw SketchServiceError.generationFailed
        }

        // Save to disk
        do {
            return try fileService.saveSketch(data: data, for: personId)
        } catch {
            throw SketchServiceError.saveFailed
        }
    }
}
