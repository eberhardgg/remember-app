import UIKit

/// Renders hair on the sketch
struct HairRenderer {
    let style: SketchStyle

    func render(in ctx: CGContext, faceRect: CGRect, hairStyle: HairStyle?, hairColor: HairColor?, variant: Int) {
        guard hairStyle != .bald else { return }

        let color = colorForHair(hairColor)
        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(style.lineColor.cgColor)
        ctx.setLineWidth(style.lineWidth * 0.8)

        switch hairStyle {
        case .short, nil:
            drawShortHair(in: ctx, faceRect: faceRect, variant: variant)
        case .long:
            drawLongHair(in: ctx, faceRect: faceRect, variant: variant)
        case .curly:
            drawCurlyHair(in: ctx, faceRect: faceRect, variant: variant)
        case .straight:
            drawStraightHair(in: ctx, faceRect: faceRect, variant: variant)
        case .wavy:
            drawWavyHair(in: ctx, faceRect: faceRect, variant: variant)
        case .ponytail:
            drawPonytail(in: ctx, faceRect: faceRect, variant: variant)
        case .bun:
            drawBun(in: ctx, faceRect: faceRect, variant: variant)
        case .buzzCut:
            drawBuzzCut(in: ctx, faceRect: faceRect, variant: variant)
        case .mohawk:
            drawMohawk(in: ctx, faceRect: faceRect, variant: variant)
        case .bald:
            break
        }
    }

    private func drawShortHair(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let path = CGMutablePath()
        let topY = faceRect.minY - 10
        let sideOffset: CGFloat = variant % 2 == 0 ? 8 : 12

        path.move(to: CGPoint(x: faceRect.minX - sideOffset, y: faceRect.minY + 30))
        path.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: topY),
            control: CGPoint(x: faceRect.minX - 5, y: topY - 10)
        )
        path.addQuadCurve(
            to: CGPoint(x: faceRect.maxX + sideOffset, y: faceRect.minY + 30),
            control: CGPoint(x: faceRect.maxX + 5, y: topY - 10)
        )
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func drawLongHair(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let path = CGMutablePath()
        let topY = faceRect.minY - 15
        let bottomY = faceRect.maxY + 30
        let sideExtend: CGFloat = 15

        // Left side
        path.move(to: CGPoint(x: faceRect.minX - sideExtend, y: faceRect.minY + 20))
        path.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: topY),
            control: CGPoint(x: faceRect.minX, y: topY)
        )
        // Right side
        path.addQuadCurve(
            to: CGPoint(x: faceRect.maxX + sideExtend, y: faceRect.minY + 20),
            control: CGPoint(x: faceRect.maxX, y: topY)
        )
        // Down right
        path.addLine(to: CGPoint(x: faceRect.maxX + sideExtend, y: bottomY))
        // Across bottom
        path.addLine(to: CGPoint(x: faceRect.minX - sideExtend, y: bottomY))
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func drawCurlyHair(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let numCurls = 10 + (variant % 4)
        let baseRadius: CGFloat = 12

        for i in 0..<numCurls {
            let angle = CGFloat(i) * (.pi * 2 / CGFloat(numCurls)) - .pi / 2
            let radiusVariation = CGFloat(i % 3) * 3
            let distance = faceRect.width / 2 + 5 + radiusVariation

            let x = faceRect.midX + cos(angle) * distance
            let y = faceRect.minY + 20 + sin(angle) * distance * 0.6

            let curlRadius = baseRadius + CGFloat(i % 3) * 2
            ctx.fillEllipse(in: CGRect(
                x: x - curlRadius,
                y: y - curlRadius,
                width: curlRadius * 2,
                height: curlRadius * 2
            ))
        }
    }

    private func drawStraightHair(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        // Similar to long but with straighter lines
        drawLongHair(in: ctx, faceRect: faceRect, variant: variant)
    }

    private func drawWavyHair(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let path = CGMutablePath()
        let topY = faceRect.minY - 12
        let bottomY = faceRect.maxY + 20
        let sideExtend: CGFloat = 12

        path.move(to: CGPoint(x: faceRect.minX - sideExtend, y: faceRect.minY + 20))
        path.addQuadCurve(
            to: CGPoint(x: faceRect.midX, y: topY),
            control: CGPoint(x: faceRect.minX, y: topY - 5)
        )
        path.addQuadCurve(
            to: CGPoint(x: faceRect.maxX + sideExtend, y: faceRect.minY + 20),
            control: CGPoint(x: faceRect.maxX, y: topY - 5)
        )

        // Wavy sides
        let waveCount = 3
        for i in 0..<waveCount {
            let startY = faceRect.minY + 20 + CGFloat(i) * 25
            let endY = startY + 25
            let waveOffset: CGFloat = (i % 2 == 0) ? 5 : -5

            path.addQuadCurve(
                to: CGPoint(x: faceRect.maxX + sideExtend + waveOffset, y: endY),
                control: CGPoint(x: faceRect.maxX + sideExtend - waveOffset, y: (startY + endY) / 2)
            )
        }

        path.addLine(to: CGPoint(x: faceRect.minX - sideExtend, y: bottomY))
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func drawPonytail(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        // Base hair
        drawShortHair(in: ctx, faceRect: faceRect, variant: variant)

        // Ponytail
        let tailX = faceRect.maxX + 10
        let tailY = faceRect.midY - 10
        let tailWidth: CGFloat = 15
        let tailLength: CGFloat = 40

        let path = CGMutablePath()
        path.move(to: CGPoint(x: faceRect.maxX, y: tailY - 10))
        path.addQuadCurve(
            to: CGPoint(x: tailX + tailWidth, y: tailY + tailLength),
            control: CGPoint(x: tailX + tailWidth + 10, y: tailY + tailLength / 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: faceRect.maxX, y: tailY + 10),
            control: CGPoint(x: tailX - 5, y: tailY + tailLength / 2)
        )
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func drawBun(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        // Base hair
        drawShortHair(in: ctx, faceRect: faceRect, variant: variant)

        // Bun on top
        let bunSize: CGFloat = 25
        let bunRect = CGRect(
            x: faceRect.midX - bunSize / 2,
            y: faceRect.minY - bunSize - 5,
            width: bunSize,
            height: bunSize
        )
        ctx.fillEllipse(in: bunRect)
    }

    private func drawBuzzCut(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        // Very short hair - just a subtle shadow on top
        let path = CGMutablePath()
        let topY = faceRect.minY

        path.addArc(
            center: CGPoint(x: faceRect.midX, y: topY + 5),
            radius: faceRect.width / 2 + 3,
            startAngle: .pi,
            endAngle: 0,
            clockwise: false
        )
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func drawMohawk(in ctx: CGContext, faceRect: CGRect, variant: Int) {
        let mohawkWidth: CGFloat = 20
        let mohawkHeight: CGFloat = 30

        let path = CGMutablePath()
        path.move(to: CGPoint(x: faceRect.midX - mohawkWidth / 2, y: faceRect.minY))
        path.addLine(to: CGPoint(x: faceRect.midX, y: faceRect.minY - mohawkHeight))
        path.addLine(to: CGPoint(x: faceRect.midX + mohawkWidth / 2, y: faceRect.minY))
        path.closeSubpath()

        ctx.addPath(path)
        ctx.fillPath()
    }

    private func colorForHair(_ color: HairColor?) -> UIColor {
        switch color {
        case .black:
            return UIColor(white: 0.1, alpha: 1)
        case .brown:
            return UIColor(red: 0.4, green: 0.26, blue: 0.13, alpha: 1)
        case .blonde:
            return UIColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1)
        case .red:
            return UIColor(red: 0.7, green: 0.25, blue: 0.1, alpha: 1)
        case .gray:
            return UIColor(white: 0.6, alpha: 1)
        case .white:
            return UIColor(white: 0.9, alpha: 1)
        case .auburn:
            return UIColor(red: 0.6, green: 0.2, blue: 0.1, alpha: 1)
        case nil:
            return UIColor(white: 0.3, alpha: 1)
        }
    }
}
