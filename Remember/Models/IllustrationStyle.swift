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
            Courtroom sketch style CARICATURE portrait. Drawn with charcoal and soft pastels on cream-colored paper. \
            Expressive, loose strokes characteristic of a skilled courtroom artist. \
            EXAGGERATE distinctive features like a political cartoonist would - big noses bigger, prominent chins more pronounced. \
            Head and shoulders view, dramatic lighting from the side. \
            Make the person INSTANTLY RECOGNIZABLE through exaggerated but tasteful features.
            """
        case .popArt:
            return """
            Pop art CARICATURE portrait in the style of Andy Warhol meets political cartoon. \
            Bold, flat colors with high contrast. Ben-Day dots pattern in the background. \
            Thick black outlines, limited color palette with vibrant primary colors. \
            EXAGGERATE the most distinctive facial features - this should be a memorable caricature, not a realistic portrait. \
            Head and shoulders view, stylized and graphic like an editorial cartoon screen print.
            """
        case .pixar3D:
            return """
            3D animated CARICATURE character portrait in the style of Pixar and Disney Animation Studios. \
            Smooth, stylized features with expressive eyes. Soft, appealing lighting. \
            EXAGGERATE distinctive features for charm and memorability - like a Pixar character designer would. \
            Big ears should be bigger, round faces rounder, long noses longer. \
            Head and shoulders view, friendly but distinctively caricatured character design.
            """
        case .vintagePolaroid:
            return """
            Vintage Polaroid instant photo style portrait with CARICATURE elements. \
            Slightly faded colors with warm nostalgic tones. Soft focus with slight vignetting. \
            While maintaining the photo aesthetic, SUBTLY EXAGGERATE the person's most distinctive features \
            to make them more memorable and recognizable. \
            The characteristic Polaroid white border frame. Authentic 1970s-80s instant camera aesthetic.
            """
        case .anime:
            return """
            Japanese anime style CARICATURE portrait with exaggerated distinctive features. \
            Clean, precise linework with cel-shaded coloring. \
            Large expressive eyes with detailed highlights. Stylized hair with defined strands. \
            EXAGGERATE the person's unique features in anime style - distinctive noses, hair styles, facial shapes. \
            Make them look like a memorable anime character based on their real features. \
            Head and shoulders view. High quality anime illustration style.
            """
        }
    }

    // MARK: - UserDefaults Storage

    private static let storageKey = "illustration_style"

    static var current: IllustrationStyle {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: storageKey),
                  let style = IllustrationStyle(rawValue: rawValue) else {
                return .vintagePolaroid
            }
            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}
