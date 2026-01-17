import SwiftUI

// MARK: - Spacing

enum Spacing {
    /// 4pt - Minimal spacing between related elements
    static let xxs: CGFloat = 4
    /// 8pt - Tight spacing
    static let xs: CGFloat = 8
    /// 12pt - Compact spacing
    static let sm: CGFloat = 12
    /// 16pt - Default spacing
    static let md: CGFloat = 16
    /// 24pt - Comfortable spacing
    static let lg: CGFloat = 24
    /// 32pt - Generous spacing
    static let xl: CGFloat = 32
    /// 40pt - Section spacing
    static let xxl: CGFloat = 40
    /// 48pt - Large section spacing
    static let xxxl: CGFloat = 48
}

// MARK: - Sizing

enum Sizing {
    /// Thumbnails and avatars
    enum Avatar {
        static let small: CGFloat = 44
        static let medium: CGFloat = 64
        static let large: CGFloat = 100
        static let xlarge: CGFloat = 150
        static let hero: CGFloat = 240
    }

    /// Record button sizes
    enum RecordButton {
        static let main: CGFloat = 100
        static let compact: CGFloat = 70
        static let pulse: CGFloat = 120
        static let pulseCompact: CGFloat = 90
        static let stopIcon: CGFloat = 32
        static let stopIconCompact: CGFloat = 24
    }

    /// Corner radii
    enum Radius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
    }

    /// Button heights
    enum Button {
        static let standard: CGFloat = 50
    }

    /// Underline/divider thickness
    static let underline: CGFloat = 2

    /// Maximum content width for centered layouts
    static let maxInputWidth: CGFloat = 200
}

// MARK: - Typography

enum Typography {
    /// Hero name display (34pt bold)
    static let heroName = Font.system(size: 34, weight: .bold)

    /// Large name display (32pt bold)
    static let largeName = Font.system(size: 32, weight: .bold)

    /// Rehearsal name (36pt bold)
    static let rehearsalName = Font.system(size: 36, weight: .bold)

    /// Mic icon size
    static let micIconLarge = Font.system(size: 40)
    static let micIconMedium = Font.system(size: 28)

    /// Placeholder icon size
    static let placeholderIcon = Font.system(size: 60)
    static let placeholderIconSmall = Font.system(size: 50)
}

// MARK: - Animation

enum Timing {
    static let quick: Double = 0.2
    static let standard: Double = 0.3
    static let slow: Double = 0.5
    static let pulse: Double = 0.8
}

// MARK: - Shadow

enum Shadow {
    static let small: CGFloat = 4
    static let medium: CGFloat = 5
    static let large: CGFloat = 10
    static let card: CGFloat = 12
}
