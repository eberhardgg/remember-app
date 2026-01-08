import Foundation

enum IllustrationStyle: String, CaseIterable, Codable {
    case courtroomSketch = "courtroom"
    case popArt = "pop_art"
    case pixar3D = "pixar_3d"
    case vintagePolaroid = "polaroid"
    case anime = "anime"

    var displayName: String {
        switch self {
        case .courtroomSketch: return "Courtroom Sketch"
        case .popArt: return "Pop Art"
        case .pixar3D: return "Pixar 3D"
        case .vintagePolaroid: return "Vintage Polaroid"
        case .anime: return "Anime"
        }
    }

    var icon: String {
        switch self {
        case .courtroomSketch: return "pencil.and.outline"
        case .popArt: return "circle.hexagongrid.fill"
        case .pixar3D: return "cube.fill"
        case .vintagePolaroid: return "camera.fill"
        case .anime: return "sparkles"
        }
    }

    var promptDescription: String {
        switch self {
        case .courtroomSketch:
            return """
            Courtroom sketch style portrait. Drawn with charcoal and soft pastels on cream-colored paper. \
            Expressive, loose strokes characteristic of a skilled courtroom artist. \
            Head and shoulders view, dramatic lighting from the side, artistic and impressionistic but recognizable. \
            The style should look like authentic courtroom art from a high-profile trial.
            """
        case .popArt:
            return """
            Pop art portrait in the style of Andy Warhol and Roy Lichtenstein. \
            Bold, flat colors with high contrast. Ben-Day dots pattern in the background. \
            Thick black outlines, limited color palette with vibrant primary colors. \
            Head and shoulders view, stylized and graphic like a screen print.
            """
        case .pixar3D:
            return """
            3D animated character portrait in the style of Pixar and Disney Animation Studios. \
            Smooth, stylized features with expressive eyes. Soft, appealing lighting. \
            Slightly exaggerated proportions for charm. Rendered look with subtle subsurface scattering on skin. \
            Head and shoulders view, friendly and approachable character design.
            """
        case .vintagePolaroid:
            return """
            Vintage Polaroid instant photo style portrait. \
            Slightly faded colors with warm nostalgic tones. Soft focus with slight vignetting. \
            Natural, candid moment captured. Subtle film grain and light leaks. \
            The characteristic Polaroid white border frame. Authentic 1970s-80s instant camera aesthetic.
            """
        case .anime:
            return """
            Japanese anime style portrait. Clean, precise linework with cel-shaded coloring. \
            Large expressive eyes with detailed highlights. Stylized hair with defined strands. \
            Soft skin shading in anime convention. Head and shoulders view. \
            High quality anime illustration style like Studio Ghibli or modern seasonal anime.
            """
        }
    }

    // MARK: - UserDefaults Storage

    private static let storageKey = "illustration_style"

    static var current: IllustrationStyle {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: storageKey),
                  let style = IllustrationStyle(rawValue: rawValue) else {
                return .courtroomSketch
            }
            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}
