import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary brand color - warm sage green (calming, natural)
    static let rememberAccent = Color("AccentColor", bundle: nil)

    // Semantic colors
    static let rememberBackground = Color(UIColor.systemBackground)
    static let rememberSecondaryBackground = Color(UIColor.secondarySystemBackground)

    // Recording states
    static let rememberRecording = Color(red: 0.92, green: 0.28, blue: 0.29) // Warm red

    // Success/confirmation
    static let rememberSuccess = Color(red: 0.30, green: 0.69, blue: 0.47) // Soft green

    // Text colors
    static let rememberPrimary = Color(UIColor.label)
    static let rememberSecondary = Color(UIColor.secondaryLabel)
    static let rememberTertiary = Color(UIColor.tertiaryLabel)

    // Card/surface colors
    static let rememberCard = Color(UIColor.systemBackground)
    static let rememberCardBorder = Color(UIColor.systemGray5)

    // Placeholder/empty state
    static let rememberPlaceholder = Color(UIColor.secondaryLabel).opacity(0.2)
}

// MARK: - Gradients

extension LinearGradient {
    static let rememberSubtle = LinearGradient(
        colors: [
            Color(UIColor.systemBackground),
            Color(UIColor.secondarySystemBackground).opacity(0.5)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Shadows

extension Color {
    static let rememberShadow = Color.black.opacity(0.15)
    static let rememberShadowLight = Color.black.opacity(0.08)
}
