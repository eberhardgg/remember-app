import UIKit

protocol SketchRendererProtocol {
    func render(features: SketchFeatures, variant: Int) -> UIImage?
}

/// Main renderer that composes all sketch components
final class SketchRenderer: SketchRendererProtocol {
    private let size: CGSize

    init(size: CGSize = CGSize(width: 200, height: 200)) {
        self.size = size
    }

    func render(features: SketchFeatures, variant: Int) -> UIImage? {
        let style = SketchStyle.variant(variant)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // Background
            style.backgroundColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Calculate face rect (centered, with padding)
            let padding: CGFloat = 25
            let faceWidth = size.width - padding * 2 - 20
            let faceHeight = faceWidth * 1.2
            let faceRect = CGRect(
                x: (size.width - faceWidth) / 2,
                y: padding + 15,
                width: faceWidth,
                height: faceHeight
            )

            // Render in layers (back to front)
            renderHair(in: ctx, faceRect: faceRect, features: features, style: style, variant: variant)
            renderFace(in: ctx, faceRect: faceRect, features: features, style: style)
            renderEyes(in: ctx, faceRect: faceRect, features: features, style: style, variant: variant)
            renderNoseAndMouth(in: ctx, faceRect: faceRect, style: style, variant: variant)

            if features.hasFacialHair {
                renderFacialHair(in: ctx, faceRect: faceRect, features: features, style: style, variant: variant)
            }

            if features.hasGlasses {
                renderGlasses(in: ctx, faceRect: faceRect, features: features, style: style, variant: variant)
            }

            // Render accessories
            renderAccessories(in: ctx, faceRect: faceRect, features: features, style: style)
        }
    }

    private func renderFace(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, style: SketchStyle) {
        let renderer = FaceShapeRenderer(style: style)
        renderer.render(in: ctx, rect: faceRect, shape: features.faceShape, skinTone: features.skinTone)
    }

    private func renderHair(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, style: SketchStyle, variant: Int) {
        let renderer = HairRenderer(style: style)
        renderer.render(in: ctx, faceRect: faceRect, hairStyle: features.hairStyle, hairColor: features.hairColor, variant: variant)
    }

    private func renderEyes(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, style: SketchStyle, variant: Int) {
        let renderer = EyesRenderer(style: style)
        renderer.render(in: ctx, faceRect: faceRect, ageRange: features.ageRange, variant: variant)
    }

    private func renderNoseAndMouth(in ctx: CGContext, faceRect: CGRect, style: SketchStyle, variant: Int) {
        let renderer = MouthRenderer(style: style)
        renderer.render(in: ctx, faceRect: faceRect, variant: variant)
    }

    private func renderGlasses(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, style: SketchStyle, variant: Int) {
        let renderer = GlassesRenderer(style: style)
        renderer.render(in: ctx, faceRect: faceRect, glassesStyle: features.glassesStyle, variant: variant)
    }

    private func renderFacialHair(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, style: SketchStyle, variant: Int) {
        let renderer = FacialHairRenderer(style: style)
        renderer.render(in: ctx, faceRect: faceRect, facialHairStyle: features.facialHairStyle, hairColor: features.hairColor, variant: variant)
    }

    private func renderAccessories(in ctx: CGContext, faceRect: CGRect, features: SketchFeatures, style: SketchStyle) {
        // Accessories are optional v1.1 feature
        // Currently just a placeholder for future expansion
    }
}
