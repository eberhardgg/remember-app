import UIKit

/// Renders eyes on the sketch
struct EyesRenderer {
    let style: SketchStyle

    func render(in ctx: CGContext, faceRect: CGRect, ageRange: AgeRange?, variant: Int) {
        let eyeY = faceRect.minY + faceRect.height * 0.4
        let eyeSpacing = faceRect.width * 0.35
        let leftEyeX = faceRect.midX - eyeSpacing / 2
        let rightEyeX = faceRect.midX + eyeSpacing / 2

        let eyeWidth: CGFloat = 12
        let eyeHeight: CGFloat = 8

        ctx.setFillColor(UIColor.white.cgColor)
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth * 0.8)

        // Eye whites
        let leftEyeRect = CGRect(
            x: leftEyeX - eyeWidth / 2,
            y: eyeY - eyeHeight / 2,
            width: eyeWidth,
            height: eyeHeight
        )
        let rightEyeRect = CGRect(
            x: rightEyeX - eyeWidth / 2,
            y: eyeY - eyeHeight / 2,
            width: eyeWidth,
            height: eyeHeight
        )

        ctx.fillEllipse(in: leftEyeRect)
        ctx.strokeEllipse(in: leftEyeRect)
        ctx.fillEllipse(in: rightEyeRect)
        ctx.strokeEllipse(in: rightEyeRect)

        // Pupils
        ctx.setFillColor(style.lineColor.cgColor)
        let pupilSize: CGFloat = 5
        let pupilOffset: CGFloat = CGFloat(variant % 3) - 1 // -1, 0, or 1 for gaze direction

        ctx.fillEllipse(in: CGRect(
            x: leftEyeX - pupilSize / 2 + pupilOffset,
            y: eyeY - pupilSize / 2,
            width: pupilSize,
            height: pupilSize
        ))
        ctx.fillEllipse(in: CGRect(
            x: rightEyeX - pupilSize / 2 + pupilOffset,
            y: eyeY - pupilSize / 2,
            width: pupilSize,
            height: pupilSize
        ))

        // Eyebrows
        drawEyebrows(in: ctx, faceRect: faceRect, leftEyeX: leftEyeX, rightEyeX: rightEyeX, eyeY: eyeY, ageRange: ageRange)

        // Wrinkles for older age
        if ageRange == .older {
            drawCrowsFeet(in: ctx, leftEyeX: leftEyeX, rightEyeX: rightEyeX, eyeY: eyeY, faceRect: faceRect)
        }
    }

    private func drawEyebrows(in ctx: CGContext, faceRect: CGRect, leftEyeX: CGFloat, rightEyeX: CGFloat, eyeY: CGFloat, ageRange: AgeRange?) {
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth)

        let browY = eyeY - 12
        let browWidth: CGFloat = 15
        let browThickness: CGFloat = ageRange == .older ? 3 : 2

        // Left eyebrow
        ctx.move(to: CGPoint(x: leftEyeX - browWidth / 2, y: browY + 2))
        ctx.addQuadCurve(
            to: CGPoint(x: leftEyeX + browWidth / 2, y: browY + 2),
            control: CGPoint(x: leftEyeX, y: browY - browThickness)
        )
        ctx.strokePath()

        // Right eyebrow
        ctx.move(to: CGPoint(x: rightEyeX - browWidth / 2, y: browY + 2))
        ctx.addQuadCurve(
            to: CGPoint(x: rightEyeX + browWidth / 2, y: browY + 2),
            control: CGPoint(x: rightEyeX, y: browY - browThickness)
        )
        ctx.strokePath()
    }

    private func drawCrowsFeet(in ctx: CGContext, leftEyeX: CGFloat, rightEyeX: CGFloat, eyeY: CGFloat, faceRect: CGRect) {
        ctx.setStrokeColor(style.lineColor.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(style.lineWidth * 0.5)

        let wrinkleLength: CGFloat = 8

        // Left side wrinkles
        for i in 0..<3 {
            let startX = leftEyeX - 15
            let startY = eyeY - 5 + CGFloat(i) * 5
            ctx.move(to: CGPoint(x: startX, y: startY))
            ctx.addLine(to: CGPoint(x: startX - wrinkleLength, y: startY - 2 + CGFloat(i) * 2))
            ctx.strokePath()
        }

        // Right side wrinkles
        for i in 0..<3 {
            let startX = rightEyeX + 15
            let startY = eyeY - 5 + CGFloat(i) * 5
            ctx.move(to: CGPoint(x: startX, y: startY))
            ctx.addLine(to: CGPoint(x: startX + wrinkleLength, y: startY - 2 + CGFloat(i) * 2))
            ctx.strokePath()
        }
    }
}
