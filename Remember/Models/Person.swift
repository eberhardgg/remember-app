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

    // Visual preference
    var preferredVisualType: VisualType

    // Review state (embedded, not a separate model)
    var lastReviewedAt: Date?
    var nextDueAt: Date
    var easeFactor: Double
    var intervalDays: Int

    init(name: String, context: String? = nil) {
        self.id = UUID()
        self.name = name
        self.context = context
        self.createdAt = Date()
        self.descriptorKeywords = []
        self.preferredVisualType = .sketch
        self.nextDueAt = Date()
        self.easeFactor = 2.5
        self.intervalDays = 1
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

    /// Whether this person is due for review
    var isDue: Bool {
        nextDueAt <= Date()
    }

    /// Days until next review (negative if overdue)
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDueAt).day ?? 0
    }
}
