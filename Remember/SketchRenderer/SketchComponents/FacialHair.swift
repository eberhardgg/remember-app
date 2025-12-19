import UIKit

/// Renders facial hair on the sketch
struct FacialHairRenderer {
    let style: SketchStyle

    func render(in ctx: CGContext, faceRect: CGRect, facialHairStyle: FacialHairStyle?, hairColor: HairColor?, variant: Int) {
        guard let facialStyle = facialHairStyle else { return }

        let color = colorForHair(hairColor)
        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth * 0.5)

        switch facialStyle {
        case .beard:
            drawBeard(in: ctx, faceRect: faceRect, variant: variant)
        case .goatee:
            drawGoatee(in: ctx, faceRect: faceRect, variant: variant)
        case .mustache:
            drawMustache(in: ctx, faceRect: faceRect, variant: variant)
        case .stubble:
            drawStubble(in: ctx, faceRect: faceRect, variant: variant)
        case .soulPatch:
            drawSoulPatch(in: ctx, faceRect: faceRect)
        }
    }

    private func drawBeard(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let path = CGMutablePath()
        let chinY = faceRect.maxY - 10
        let beardBottom = chinY + 25 + CGFloat(variant % 3) * 5

        path.move(to: CGPoint(x: faceRect.minX + 20, y: faceRect.midY + 20))
        path.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: beardBottom),
            control: CGPoint(x: faceRect.minX + 10, y: chinY + 10)
        )
        path.addQuadCurve(
            to: CGPoint(x: faceRect.maxX - 20, y: faceRect.midY + 20),
            control: CGPoint(x: faceRect.maxX - 10, y: chinY + 10)
        )
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()

        // Add mustache with beard
        drawMustache(in: ctx, faceRect: faceRect, variant: variant)
    }

    private func drawGoatee(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let chinY = faceRect.maxY - 10
        let goateeWidth: CGFloat = 30
        let goateeHeight: CGFloat = 25 + CGFloat(variant % 2) * 5

        let path = CGMutablePath()
        path.move(to: CGPoint(x: faceRect.midX - goateeWidth / 2, y: chinY - 15))
        path.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: chinY + goateeHeight - 10),
            control: CGPoint(x: faceRect.midX - goateeWidth / 3, y: chinY + goateeHeight / 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: faceRect.midX + goateeWidth / 2, y: chinY - 15),
            control: CGPoint(x: faceRect.midX + goateeWidth / 3, y: chinY + goateeHeight / 2)
        )
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func drawMustache(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let mustacheY = faceRect.minY + faceRect.height * 0.62
        let mustacheWidth: CGFloat = 35 + CGFloat(variant % 2) * 10
        let mustacheHeight: CGFloat = 8

        // Left side
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: faceRect.midX, y: mustacheY))
        leftPath.addQuadCurve(
            to: CGPoint(x: faceRect.midX - mustacheWidth / 2, y: mustacheY + 5),
            control: CGPoint(x: faceRect.midX - mustacheWidth / 4, y: mustacheY - mustacheHeight)
        )
        leftPath.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: mustacheY + mustacheHeight),
            control: CGPoint(x: faceRect.midX - mustacheWidth / 4, y: mustacheY + mustacheHeight + 3)
        )
        leftPath.closeSubpath()

        // Right side (mirror)
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: faceRect.midX, y: mustacheY))
        rightPath.addQuadCurve(
            to: CGPoint(x: faceRect.midX + mustacheWidth / 2, y: mustacheY + 5),
            control: CGPoint(x: faceRect.midX + mustacheWidth / 4, y: mustacheY - mustacheHeight)
        )
        rightPath.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: mustacheY + mustacheHeight),
            control: CGPoint(x: faceRect.midX + mustacheWidth / 4, y: mustacheY + mustacheHeight + 3)
        )
        rightPath.closeSubpath()

        ctx.addPath(leftPath)
        ctx.fillPath()
        ctx.addPath(rightPath)
        ctx.fillPath()
    }

    private func drawStubble(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let stubbleArea = CGRect(
            x: faceRect.minX + 25,
            y: faceRect.midY + 10,
            width: faceRect.width - 50,
            height: faceRect.height * 0.35
        )

        let dotCount = 40 + variant * 10

        for _ in 0..<dotCount {
            let x = stubbleArea.minX + CGFloat.random(in: 0...stubbleArea.width)
            let y = stubbleArea.minY + CGFloat.random(in: 0...stubbleArea.height)

            // Only draw dots within the face area (rough oval check)
            let normalizedX = (x - faceRect.midX) / (faceRect.width / 2)
            let normalizedY = (y - faceRect.midY) / (faceRect.height / 2)
            if normalizedX * normalizedX + normalizedY * normalizedY < 0.9 {
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
            }
        }
    }

    private func drawSoulPatch(in ctx: CGContext, faceRect: CGRect) {
        let patchY = faceRect.maxY - 25
        let patchWidth: CGFloat = 10
        let patchHeight: CGFloat = 12

        ctx.fillEllipse(in: CGRect(
            x: faceRect.midX - patchWidth / 2,
            y: patchY,
            width: patchWidth,
            height: patchHeight
        ))
    }

    private func colorForHair(_ color: HairColor?) -> UIColor {
        switch color {
        case .black:
            return UIColor(white: 0.1, alpha: 1)
        case .brown:
            return UIColor(red: 0.4, green: 0.26, blue: 0.13, alpha: 1)
        case .blonde:
            return UIColor(red: 0.8, green: 0.7, blue: 0.4, alpha: 1)
        case .red:
            return UIColor(red: 0.6, green: 0.2, blue: 0.1, alpha: 1)
        case .gray:
            return UIColor(white: 0.5, alpha: 1)
        case .white:
            return UIColor(white: 0.85, alpha: 1)
        case .auburn:
            return UIColor(red: 0.5, green: 0.18, blue: 0.08, alpha: 1)
        case nil:
            return UIColor(white: 0.25, alpha: 1)
        }
    }
}
