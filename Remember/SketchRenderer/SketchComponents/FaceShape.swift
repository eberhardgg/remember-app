import UIKit

/// Renders the base face shape
struct FaceShapeRenderer {
    let style: SketchStyle

    func render(in ctx: CGContext, rect: CGRect, shape: FaceShape?, skinTone: SkinTone?) {
        let skinColor = colorForSkinTone(skinTone)

        ctx.setFillColor(skinColor.cgColor)
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth)

        switch shape {
        case .round:
            ctx.fillEllipse(in: rect)
            ctx.strokeEllipse(in: rect)

        case .square:
            let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.15)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            ctx.addPath(path.cgPath)
            ctx.strokePath()

        case .long:
            let elongatedRect = CGRect(
                x: rect.minX + rect.width * 0.1,
                y: rect.minY - rect.height * 0.05,
                width: rect.width * 0.8,
                height: rect.height * 1.1
            )
            ctx.fillEllipse(in: elongatedRect)
            ctx.strokeEllipse(in: elongatedRect)

        case .heart:
            drawHeartFace(in: ctx, rect: rect)

        case .oval, nil:
            // Default oval
            ctx.fillEllipse(in: rect)
            ctx.strokeEllipse(in: rect)
        }
    }

    private func drawHeartFace(in ctx: CGContext, rect: CGRect) {
        let path = CGMutablePath()
        let midX = rect.midX
        let topY = rect.minY + rect.height * 0.15
        let bottomY = rect.maxY

        path.move(to: CGPoint(x: midX, y: bottomY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: topY + rect.height * 0.2),
            control1: CGPoint(x: rect.minX + rect.width * 0.1, y: bottomY - rect.height * 0.2),
            control2: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: topY),
            control: CGPoint(x: rect.minX + rect.width * 0.2, y: topY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: topY + rect.height * 0.2),
            control: CGPoint(x: rect.maxX - rect.width * 0.2, y: topY)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: bottomY),
            control1: CGPoint(x: rect.maxX, y: rect.midY),
            control2: CGPoint(x: rect.maxX - rect.width * 0.1, y: bottomY - rect.height * 0.2)
        )
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
        ctx.addPath(path)
        ctx.strokePath()
    }

    private func colorForSkinTone(_ tone: SkinTone?) -> UIColor {
        switch tone {
        case .light:
            return UIColor(red: 1.0, green: 0.87, blue: 0.77, alpha: 1.0)
        case .medium:
            return UIColor(red: 0.87, green: 0.72, blue: 0.53, alpha: 1.0)
        case .tan:
            return UIColor(red: 0.76, green: 0.57, blue: 0.42, alpha: 1.0)
        case .dark:
            return UIColor(red: 0.55, green: 0.38, blue: 0.28, alpha: 1.0)
        case nil:
            return UIColor(red: 0.95, green: 0.82, blue: 0.70, alpha: 1.0) // Default warm tone
        }
    }
}
