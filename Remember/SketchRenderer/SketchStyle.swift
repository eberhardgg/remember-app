import UIKit

/// Visual style configuration for sketches
struct SketchStyle {
    let lineWidth: CGFloat
    let lineColor: UIColor
    let backgroundColor: UIColor
    let shadowRadius: CGFloat
    let cornerRadius: CGFloat

    static let `default` = SketchStyle(
        lineWidth: 2.0,
        lineColor: .label,
        backgroundColor: .systemBackground,
        shadowRadius: 0,
        cornerRadius: 0
    )

    static let sketchy = SketchStyle(
        lineWidth: 1.5,
        lineColor: UIColor(white: 0.2, alpha: 1.0),
        backgroundColor: UIColor(white: 0.98, alpha: 1.0),
        shadowRadius: 2,
        cornerRadius: 0
    )

    static let bold = SketchStyle(
        lineWidth: 3.0,
        lineColor: .black,
        backgroundColor: .white,
        shadowRadius: 0,
        cornerRadius: 0
    )

    /// Returns a variant style based on the variant number
    static func variant(_ number: Int) -> SketchStyle {
        let styles: [SketchStyle] = [.default, .sketchy, .bold]
        return styles[number % styles.count]
    }
}
