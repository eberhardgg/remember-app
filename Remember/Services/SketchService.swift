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
    func generateSketch(from transcript: String?, keywords: [String], for personId: UUID) async throws -> String
    func regenerateSketch(from transcript: String?, keywords: [String], for personId: UUID) async throws -> String
}

final class SketchService: SketchServiceProtocol {
    private let fileService: FileServiceProtocol
    private let keywordParser: KeywordParserProtocol
    private let renderer: SketchRendererProtocol
    private let openAIService: OpenAIImageServiceProtocol

    init(
        fileService: FileServiceProtocol,
        keywordParser: KeywordParserProtocol,
        renderer: SketchRendererProtocol,
        openAIService: OpenAIImageServiceProtocol = OpenAIImageService()
    ) {
        self.fileService = fileService
        self.keywordParser = keywordParser
        self.renderer = renderer
        self.openAIService = openAIService
    }

    func generateSketch(from transcript: String?, keywords: [String], for personId: UUID) async throws -> String {
        print("[SketchService] generateSketch called")
        print("[SketchService] hasAPIKey: \(openAIService.hasAPIKey)")
        print("[SketchService] transcript: \(transcript ?? "nil")")

        // Try OpenAI first if API key is configured
        if openAIService.hasAPIKey, let transcript = transcript, !transcript.isEmpty {
            print("[SketchService] Using OpenAI")
            return try await generateWithOpenAI(transcript: transcript, keywords: keywords, for: personId)
        }

        // Fall back to local renderer
        print("[SketchService] Falling back to local renderer")
        return try await generateLocally(from: keywords, for: personId, variant: 0)
    }

    func regenerateSketch(from transcript: String?, keywords: [String], for personId: UUID) async throws -> String {
        // Try OpenAI first if API key is configured
        if openAIService.hasAPIKey, let transcript = transcript, !transcript.isEmpty {
            return try await generateWithOpenAI(transcript: transcript, keywords: keywords, for: personId)
        }

        // Fall back to local renderer with random variant
        let variant = Int.random(in: 1...5)
        return try await generateLocally(from: keywords, for: personId, variant: variant)
    }

    private func generateWithOpenAI(transcript: String, keywords: [String], for personId: UUID) async throws -> String {
        let image = try await openAIService.generateSketch(from: transcript, keywords: keywords)

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

    private func generateLocally(from keywords: [String], for personId: UUID, variant: Int) async throws -> String {
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
