import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var name: String
    var context: String?
    var createdAt: Date

    // File paths (relative to Documents/)
    var audioNotePath: String?
    var sketchImagePath: String?
    var photoImagePath: String?

    // Transcript data
    var transcriptText: String?
    var descriptorKeywords: [String]

    // Name etymology/meaning for memory hook
    var nameMeaning: String?

    // Visual preference
    var preferredVisualType: VisualType

    // Illustration style used for this person's sketch
    var illustrationStyle: IllustrationStyle?

    // AI-edited coherent description (cleaned up from voice ramble)
    var editedDescription: String?

    init(name: String, context: String? = nil) {
        self.id = UUID()
        self.name = name
        self.context = context
        self.createdAt = Date()
        self.descriptorKeywords = []
        self.preferredVisualType = .sketch
    }

    /// Returns the URL for the preferred visual (sketch or photo)
    var preferredVisualURL: URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        switch preferredVisualType {
        case .sketch:
            guard let path = sketchImagePath else { return nil }
            return documentsURL?.appendingPathComponent(path)
        case .photo:
            guard let path = photoImagePath else { return nil }
            return documentsURL?.appendingPathComponent(path)
        }
    }
}
