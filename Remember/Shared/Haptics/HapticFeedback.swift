import UIKit

/// Centralized haptic feedback for the app
enum HapticFeedback {

    // MARK: - Impact Feedback

    /// Light tap - for subtle UI interactions
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium tap - for standard buttons
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy tap - for significant actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success - task completed successfully
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning - something needs attention
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error - something went wrong
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection changed - for pickers, toggles
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - App-Specific Haptics

    /// Recording started
    static func recordingStarted() {
        medium()
    }

    /// Recording stopped
    static func recordingStopped() {
        heavy()
    }

    /// Person saved successfully
    static func personSaved() {
        success()
    }

    /// Sketch generated
    static func sketchGenerated() {
        light()
    }

    /// Button tap
    static func buttonTap() {
        light()
    }
}
