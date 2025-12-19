import UIKit

/// Renders the mouth on the sketch
struct MouthRenderer {
    let style: SketchStyle

    func render(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth)

        let mouthY = faceRect.minY + faceRect.height * 0.72
        let mouthWidth: CGFloat = 25

        // Different mouth expressions based on variant
        switch variant % 4 {
        case 0:
            // Slight smile
            drawSmile(in: ctx, x: faceRect.midX, y: mouthY, width: mouthWidth, intensity: 8)
        case 1:
            // Neutral
            drawNeutral(in: ctx, x: faceRect.midX, y: mouthY, width: mouthWidth)
        case 2:
            // Bigger smile
            drawSmile(in: ctx, x: faceRect.midX, y: mouthY, width: mouthWidth, intensity: 12)
        case 3:
            // Closed smile
            drawClosedSmile(in: ctx, x: faceRect.midX, y: mouthY, width: mouthWidth)
        default:
            drawSmile(in: ctx, x: faceRect.midX, y: mouthY, width: mouthWidth, intensity: 8)
        }

        // Add nose
        drawNose(in: ctx, faceRect: faceRect)
    }

    private func drawSmile(in ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, intensity: CGFloat) {
        ctx.move(to: CGPoint(x: x - width / 2, y: y))
        ctx.addQuadCurve(
            to: CGPoint(x: x + width / 2, y: y),
            control: CGPoint(x: x, y: y + intensity)
        )
        ctx.strokePath()
    }

    private func drawNeutral(in ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat) {
        ctx.move(to: CGPoint(x: x - width / 2, y: y))
        ctx.addLine(to: CGPoint(x: x + width / 2, y: y))
        ctx.strokePath()
    }

    private func drawClosedSmile(in ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat) {
        ctx.move(to: CGPoint(x: x - width / 2, y: y))
        ctx.addQuadCurve(
            to: CGPoint(x: x + width / 2, y: y),
            control: CGPoint(x: x, y: y + 6)
        )
        ctx.strokePath()

        // Small line at corners
        ctx.move(to: CGPoint(x: x - width / 2, y: y - 2))
        ctx.addLine(to: CGPoint(x: x - width / 2 + 3, y: y))
        ctx.strokePath()

        ctx.move(to: CGPoint(x: x + width / 2, y: y - 2))
        ctx.addLine(to: CGPoint(x: x + width / 2 - 3, y: y))
        ctx.strokePath()
    }

    private func drawNose(in ctx: CGContext, faceRect: CGRect) {
        let noseY = faceRect.minY + faceRect.height * 0.52
        let noseWidth: CGFloat = 12

        ctx.move(to: CGPoint(x: faceRect.midX, y: noseY - 10))
        ctx.addQuadCurve(
            to: CGPoint(x: faceRect.midX + noseWidth / 2, y: noseY + 5),
            control: CGPoint(x: faceRect.midX + noseWidth / 3, y: noseY)
        )
        ctx.strokePath()
    }
}
