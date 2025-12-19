import UIKit

/// Renders glasses on the sketch
struct GlassesRenderer {
    let style: SketchStyle

    func render(in ctx: CGContext, faceRect: CGRect, glassesStyle: GlassesStyle?, variant: Int) {
        let glassStyle = glassesStyle ?? .rectangular

        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth)

        let eyeY = faceRect.minY + faceRect.height * 0.38
        let glassWidth: CGFloat = 28
        let glassHeight: CGFloat = glassStyle == .aviator ? 28 : 22
        let eyeSpacing = faceRect.width * 0.35
        let leftX = faceRect.midX - eyeSpacing / 2 - glassWidth / 2
        let rightX = faceRect.midX + eyeSpacing / 2 - glassWidth / 2

        switch glassStyle {
        case .round:
            drawRoundGlasses(in: ctx, leftX: leftX, rightX: rightX, eyeY: eyeY, size: glassWidth)
        case .square:
            drawSquareGlasses(in: ctx, leftX: leftX, rightX: rightX, eyeY: eyeY, width: glassWidth, height: glassHeight)
        case .rectangular:
            drawRectangularGlasses(in: ctx, leftX: leftX, rightX: rightX, eyeY: eyeY, width: glassWidth, height: glassHeight * 0.7)
        case .aviator:
            drawAviatorGlasses(in: ctx, leftX: leftX, rightX: rightX, eyeY: eyeY, width: glassWidth, height: glassHeight)
        }

        // Bridge
        let bridgeY = eyeY + 2
        ctx.move(to: CGPoint(x: leftX + glassWidth, y: bridgeY))
        ctx.addLine(to: CGPoint(x: rightX, y: bridgeY))
        ctx.strokePath()

        // Temples (arms)
        let templeY = eyeY
        ctx.move(to: CGPoint(x: leftX, y: templeY))
        ctx.addLine(to: CGPoint(x: leftX - 15, y: templeY - 5))
        ctx.strokePath()

        ctx.move(to: CGPoint(x: rightX + glassWidth, y: templeY))
        ctx.addLine(to: CGPoint(x: rightX + glassWidth + 15, y: templeY - 5))
        ctx.strokePath()
    }

    private func drawRoundGlasses(in ctx: CGContext, leftX: CGFloat, rightX: CGFloat, eyeY: CGFloat, size: CGFloat) {
        let leftRect = CGRect(x: leftX, y: eyeY - size / 2 + 5, width: size, height: size)
        let rightRect = CGRect(x: rightX, y: eyeY - size / 2 + 5, width: size, height: size)

        ctx.strokeEllipse(in: leftRect)
        ctx.strokeEllipse(in: rightRect)
    }

    private func drawSquareGlasses(in ctx: CGContext, leftX: CGFloat, rightX: CGFloat, eyeY: CGFloat, width: CGFloat, height: CGFloat) {
        let cornerRadius: CGFloat = 3
        let leftRect = CGRect(x: leftX, y: eyeY - height / 2 + 5, width: width, height: height)
        let rightRect = CGRect(x: rightX, y: eyeY - height / 2 + 5, width: width, height: height)

        let leftPath = UIBezierPath(roundedRect: leftRect, cornerRadius: cornerRadius)
        let rightPath = UIBezierPath(roundedRect: rightRect, cornerRadius: cornerRadius)

        ctx.addPath(leftPath.cgPath)
        ctx.strokePath()
        ctx.addPath(rightPath.cgPath)
        ctx.strokePath()
    }

    private func drawRectangularGlasses(in ctx: CGContext, leftX: CGFloat, rightX: CGFloat, eyeY: CGFloat, width: CGFloat, height: CGFloat) {
        let cornerRadius: CGFloat = 2
        let leftRect = CGRect(x: leftX, y: eyeY - height / 2 + 5, width: width, height: height)
        let rightRect = CGRect(x: rightX, y: eyeY - height / 2 + 5, width: width, height: height)

        let leftPath = UIBezierPath(roundedRect: leftRect, cornerRadius: cornerRadius)
        let rightPath = UIBezierPath(roundedRect: rightRect, cornerRadius: cornerRadius)

        ctx.addPath(leftPath.cgPath)
        ctx.strokePath()
        ctx.addPath(rightPath.cgPath)
        ctx.strokePath()
    }

    private func drawAviatorGlasses(in ctx: CGContext, leftX: CGFloat, rightX: CGFloat, eyeY: CGFloat, width: CGFloat, height: CGFloat) {
        // Aviator shape - teardrop-ish
        let drawAviator = { (x: CGFloat) in
            let path = CGMutablePath()
            let topY = eyeY - height / 2 + 8
            let bottomY = eyeY + height / 2 + 5

            path.move(to: CGPoint(x: x + width / 2, y: topY))
            path.addQuadCurve(
                to: CGPoint(x: x + width, y: eyeY + 5),
                control: CGPoint(x: x + width, y: topY)
            )
            path.addQuadCurve(
                to: CGPoint(x: x + width / 2, y: bottomY),
                control: CGPoint(x: x + width, y: bottomY)
            )
            path.addQuadCurve(
                to: CGPoint(x: x, y: eyeY + 5),
                control: CGPoint(x: x, y: bottomY)
            )
            path.addQuadCurve(
                to: CGPoint(x: x + width / 2, y: topY),
                control: CGPoint(x: x, y: topY)
            )

            ctx.addPath(path)
            ctx.strokePath()
        }

        drawAviator(leftX)
        drawAviator(rightX)
    }
}
