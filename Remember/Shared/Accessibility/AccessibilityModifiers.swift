import SwiftUI

// MARK: - Accessibility Labels

extension View {
    /// Adds accessibility for a person card
    func personCardAccessibility(name: String, context: String?, isDue: Bool) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(personCardLabel(name: name, context: context, isDue: isDue))
            .accessibilityHint("Double tap to view details")
    }

    private func personCardLabel(name: String, context: String?, isDue: Bool) -> String {
        var label = name
        if let context = context {
            label += ", \(context)"
        }
        if isDue {
            label += ", due for review"
        }
        return label
    }

    /// Adds accessibility for a flashcard
    func flashcardAccessibility(isRevealed: Bool, personName: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isRevealed ? "Flashcard showing \(personName)" : "Flashcard, name hidden")
            .accessibilityHint(isRevealed ? "Swipe right if you got it, left if you missed it" : "Double tap to reveal name")
    }

    /// Adds accessibility for the record button
    func recordButtonAccessibility(isRecording: Bool) -> some View {
        self
            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
            .accessibilityHint(isRecording ? "Double tap to stop" : "Double tap to start recording your voice description")
            .accessibilityAddTraits(.isButton)
    }

    /// Adds accessibility for sketch thumbnail
    func sketchAccessibility(personName: String, hasSketch: Bool) -> some View {
        self
            .accessibilityLabel(hasSketch ? "Memory sketch of \(personName)" : "No sketch for \(personName)")
    }
}

// MARK: - Accessibility Announcements

enum AccessibilityAnnouncement {
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    static func recordingStarted() {
        announce("Recording started")
    }

    static func recordingStopped() {
        announce("Recording stopped. Processing your description.")
    }

    static func sketchGenerated() {
        announce("Memory sketch created")
    }

    static func reviewCorrect() {
        announce("Correct! Moving to next card.")
    }

    static func reviewIncorrect() {
        announce("Missed. Moving to next card.")
    }

    static func reviewComplete() {
        announce("Review session complete")
    }

    static func personAdded(name: String) {
        announce("\(name) added to Remember")
    }
}
