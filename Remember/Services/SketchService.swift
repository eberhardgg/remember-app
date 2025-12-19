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

// MARK: - Keyword Parser

protocol KeywordParserProtocol {
    func extractKeywords(from transcript: String) -> [String]
    func parse(_ keywords: [String]) -> SketchFeatures
}

struct SketchFeatures {
    var hairColor: HairColor?
    var hairStyle: HairStyle?
    var hasGlasses: Bool
    var hasFacialHair: Bool
    var facialHairStyle: FacialHairStyle?
    var ageRange: AgeRange?
    var faceShape: FaceShape?

    static let `default` = SketchFeatures(
        hairColor: nil,
        hairStyle: nil,
        hasGlasses: false,
        hasFacialHair: false,
        facialHairStyle: nil,
        ageRange: nil,
        faceShape: nil
    )
}

enum HairColor: String, CaseIterable {
    case black, brown, blonde, red, gray, white
}

enum HairStyle: String, CaseIterable {
    case short, long, curly, straight, wavy, bald, ponytail, bun
}

enum FacialHairStyle: String, CaseIterable {
    case beard, goatee, mustache, stubble
}

enum AgeRange: String, CaseIterable {
    case young, middle, older
}

enum FaceShape: String, CaseIterable {
    case round, oval, square, long
}

final class KeywordParser: KeywordParserProtocol {
    private let hairColorKeywords: [String: HairColor] = [
        "black hair": .black, "dark hair": .black,
        "brown hair": .brown, "brunette": .brown,
        "blonde": .blonde, "blond": .blonde, "light hair": .blonde,
        "red hair": .red, "redhead": .red, "ginger": .red,
        "gray hair": .gray, "grey hair": .gray, "silver hair": .gray,
        "white hair": .white
    ]

    private let hairStyleKeywords: [String: HairStyle] = [
        "short hair": .short, "buzz cut": .short,
        "long hair": .long,
        "curly": .curly, "curls": .curly,
        "straight hair": .straight,
        "wavy": .wavy,
        "bald": .bald, "no hair": .bald, "shaved head": .bald,
        "ponytail": .ponytail,
        "bun": .bun, "hair bun": .bun
    ]

    private let glassesKeywords = ["glasses", "spectacles", "eyeglasses", "wears glasses"]
    private let facialHairKeywords: [String: FacialHairStyle] = [
        "beard": .beard, "bearded": .beard, "full beard": .beard,
        "goatee": .goatee,
        "mustache": .mustache, "moustache": .mustache,
        "stubble": .stubble, "five o'clock shadow": .stubble
    ]

    func extractKeywords(from transcript: String) -> [String] {
        // Simple keyword extraction: split into words and common phrases
        let lowercased = transcript.lowercased()
        var keywords: [String] = []

        // Check for known feature phrases
        let allPhrases = Array(hairColorKeywords.keys) +
                         Array(hairStyleKeywords.keys) +
                         glassesKeywords +
                         Array(facialHairKeywords.keys)

        for phrase in allPhrases {
            if lowercased.contains(phrase) {
                keywords.append(phrase)
            }
        }

        return keywords
    }

    func parse(_ keywords: [String]) -> SketchFeatures {
        var features = SketchFeatures.default

        for keyword in keywords {
            let lower = keyword.lowercased()

            // Check hair color
            for (phrase, color) in hairColorKeywords {
                if lower.contains(phrase) {
                    features.hairColor = color
                }
            }

            // Check hair style
            for (phrase, style) in hairStyleKeywords {
                if lower.contains(phrase) {
                    features.hairStyle = style
                }
            }

            // Check glasses
            for phrase in glassesKeywords {
                if lower.contains(phrase) {
                    features.hasGlasses = true
                }
            }

            // Check facial hair
            for (phrase, style) in facialHairKeywords {
                if lower.contains(phrase) {
                    features.hasFacialHair = true
                    features.facialHairStyle = style
                }
            }
        }

        return features
    }
}

// MARK: - Sketch Renderer

protocol SketchRendererProtocol {
    func render(features: SketchFeatures, variant: Int) -> UIImage?
}

final class SketchRenderer: SketchRendererProtocol {
    private let size = CGSize(width: 200, height: 200)

    func render(features: SketchFeatures, variant: Int) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // Background
            UIColor.systemBackground.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Draw face (simple oval)
            let faceRect = CGRect(x: 50, y: 40, width: 100, height: 120)
            drawFace(in: ctx, rect: faceRect, features: features, variant: variant)

            // Draw hair
            drawHair(in: ctx, faceRect: faceRect, features: features, variant: variant)

            // Draw glasses if present
            if features.hasGlasses {
                drawGlasses(in: ctx, faceRect: faceRect, variant: variant)
            }

            // Draw facial hair if present
            if features.hasFacialHair {
                drawFacialHair(in: ctx, faceRect: faceRect, features: features, variant: variant)
            }
        }
    }

    private func drawFace(in ctx: CGContext, rect: CGRect, features: SketchFeatures, variant: Int) {
        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: rect)

        // Simple eyes
        let eyeY = rect.minY + rect.height * 0.4
        let leftEyeX = rect.minX + rect.width * 0.3
        let rightEyeX = rect.minX + rect.width * 0.7
        let eyeSize: CGFloat = 6

        ctx.fillEllipse(in: CGRect(x: leftEyeX - eyeSize/2, y: eyeY, width: eyeSize, height: eyeSize))
        ctx.fillEllipse(in: CGRect(x: rightEyeX - eyeSize/2, y: eyeY, width: eyeSize, height: eyeSize))

        // Simple mouth
        let mouthY = rect.minY + rect.height * 0.7
        ctx.move(to: CGPoint(x: rect.minX + rect.width * 0.35, y: mouthY))
        ctx.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.65, y: mouthY),
            control: CGPoint(x: rect.midX, y: mouthY + 10)
        )
        ctx.strokePath()
    }

    private func drawHair(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, variant: Int) {
        guard features.hairStyle != .bald else { return }

        let hairColor = colorForHair(features.hairColor)
        ctx.setFillColor(hairColor.cgColor)
        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.5)

        switch features.hairStyle {
        case .short, nil:
            // Simple short hair arc
            let hairRect = CGRect(
                x: faceRect.minX - 5,
                y: faceRect.minY - 15,
                width: faceRect.width + 10,
                height: 40
            )
            ctx.addArc(
                center: CGPoint(x: faceRect.midX, y: faceRect.minY),
                radius: faceRect.width / 2 + 5,
                startAngle: .pi,
                endAngle: 0,
                clockwise: false
            )
            ctx.fillPath()

        case .long:
            // Long hair extending down
            let path = CGMutablePath()
            path.move(to: CGPoint(x: faceRect.minX - 10, y: faceRect.minY + 20))
            path.addQuadCurve(
                to: CGPoint(x: faceRect.midX, y: faceRect.minY - 20),
                control: CGPoint(x: faceRect.minX, y: faceRect.minY - 10)
            )
            path.addQuadCurve(
                to: CGPoint(x: faceRect.maxX + 10, y: faceRect.minY + 20),
                control: CGPoint(x: faceRect.maxX, y: faceRect.minY - 10)
            )
            path.addLine(to: CGPoint(x: faceRect.maxX + 10, y: faceRect.maxY + 20))
            path.addLine(to: CGPoint(x: faceRect.minX - 10, y: faceRect.maxY + 20))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.fillPath()

        case .curly:
            // Curly hair with circles
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                let x = faceRect.midX + cos(angle) * (faceRect.width / 2 + 10)
                let y = faceRect.minY - 5 + sin(angle) * 20
                ctx.fillEllipse(in: CGRect(x: x - 8, y: y - 8, width: 16, height: 16))
            }

        default:
            // Default to short hair
            ctx.addArc(
                center: CGPoint(x: faceRect.midX, y: faceRect.minY),
                radius: faceRect.width / 2 + 5,
                startAngle: .pi,
                endAngle: 0,
                clockwise: false
            )
            ctx.fillPath()
        }
    }

    private func drawGlasses(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(2)

        let eyeY = faceRect.minY + faceRect.height * 0.38
        let glassSize: CGFloat = 25
        let leftX = faceRect.minX + faceRect.width * 0.2
        let rightX = faceRect.minX + faceRect.width * 0.55

        // Left lens
        ctx.strokeEllipse(in: CGRect(x: leftX, y: eyeY - 5, width: glassSize, height: glassSize * 0.8))
        // Right lens
        ctx.strokeEllipse(in: CGRect(x: rightX, y: eyeY - 5, width: glassSize, height: glassSize * 0.8))
        // Bridge
        ctx.move(to: CGPoint(x: leftX + glassSize, y: eyeY + 5))
        ctx.addLine(to: CGPoint(x: rightX, y: eyeY + 5))
        ctx.strokePath()
    }

    private func drawFacialHair(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, variant: Int) {
        ctx.setFillColor(colorForHair(features.hairColor).cgColor)

        let chinY = faceRect.maxY - 15

        switch features.facialHairStyle {
        case .beard, nil:
            // Full beard
            let beardPath = CGMutablePath()
            beardPath.move(to: CGPoint(x: faceRect.minX + 15, y: chinY - 20))
            beardPath.addQuadCurve(
                to: CGPoint(x: faceRect.maxX - 15, y: chinY - 20),
                control: CGPoint(x: faceRect.midX, y: faceRect.maxY + 20)
            )
            ctx.addPath(beardPath)
            ctx.fillPath()

        case .mustache:
            // Mustache only
            let mustacheY = faceRect.minY + faceRect.height * 0.6
            ctx.fillEllipse(in: CGRect(x: faceRect.midX - 20, y: mustacheY, width: 40, height: 10))

        case .goatee:
            // Goatee
            ctx.fillEllipse(in: CGRect(x: faceRect.midX - 15, y: chinY - 5, width: 30, height: 25))

        case .stubble:
            // Dots for stubble
            for _ in 0..<20 {
                let x = faceRect.midX + CGFloat.random(in: -30...30)
                let y = chinY + CGFloat.random(in: -20...10)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
            }
        }
    }

    private func colorForHair(_ color: HairColor?) -> UIColor {
        switch color {
        case .black: return UIColor(white: 0.1, alpha: 1)
        case .brown: return UIColor(red: 0.4, green: 0.26, blue: 0.13, alpha: 1)
        case .blonde: return UIColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1)
        case .red: return UIColor(red: 0.7, green: 0.25, blue: 0.1, alpha: 1)
        case .gray: return UIColor(white: 0.6, alpha: 1)
        case .white: return UIColor(white: 0.9, alpha: 1)
        case nil: return UIColor(white: 0.3, alpha: 1)
        }
    }
}
