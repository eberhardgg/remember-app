import Foundation

protocol KeywordParserProtocol {
    func extractKeywords(from transcript: String) -> [String]
    func parse(_ keywords: [String]) -> SketchFeatures
}

/// Parses transcript text to extract visual keywords and features
final class KeywordParser: KeywordParserProtocol {

    // MARK: - Keyword Dictionaries

    private let hairColorKeywords: [String: HairColor] = [
        "black hair": .black, "dark hair": .black,
        "brown hair": .brown, "brunette": .brown,
        "blonde": .blonde, "blond": .blonde, "light hair": .blonde, "golden hair": .blonde,
        "red hair": .red, "redhead": .red, "ginger": .red,
        "gray hair": .gray, "grey hair": .gray, "silver hair": .gray,
        "white hair": .white,
        "auburn": .auburn, "auburn hair": .auburn
    ]

    private let hairStyleKeywords: [String: HairStyle] = [
        "short hair": .short, "buzz cut": .buzzCut, "buzzcut": .buzzCut,
        "long hair": .long,
        "curly": .curly, "curls": .curly, "curly hair": .curly,
        "straight hair": .straight,
        "wavy": .wavy, "wavy hair": .wavy,
        "bald": .bald, "no hair": .bald, "shaved head": .bald, "balding": .bald,
        "ponytail": .ponytail, "pony tail": .ponytail,
        "bun": .bun, "hair bun": .bun, "top knot": .bun,
        "mohawk": .mohawk
    ]

    private let glassesKeywords: [String: GlassesStyle] = [
        "glasses": .rectangular,
        "spectacles": .rectangular,
        "eyeglasses": .rectangular,
        "wears glasses": .rectangular,
        "round glasses": .round,
        "square glasses": .square,
        "rectangular glasses": .rectangular,
        "aviators": .aviator,
        "aviator glasses": .aviator
    ]

    private let facialHairKeywords: [String: FacialHairStyle] = [
        "beard": .beard, "bearded": .beard, "full beard": .beard, "big beard": .beard,
        "goatee": .goatee,
        "mustache": .mustache, "moustache": .mustache,
        "stubble": .stubble, "five o'clock shadow": .stubble, "scruffy": .stubble,
        "soul patch": .soulPatch
    ]

    private let ageKeywords: [String: AgeRange] = [
        "young": .young, "twenties": .young, "in their 20s": .young,
        "middle aged": .middle, "middle-aged": .middle, "thirties": .middle,
        "forties": .middle, "in their 30s": .middle, "in their 40s": .middle,
        "older": .older, "elderly": .older, "senior": .older,
        "fifties": .older, "sixties": .older, "gray": .older
    ]

    private let faceShapeKeywords: [String: FaceShape] = [
        "round face": .round, "chubby": .round, "full face": .round,
        "oval face": .oval,
        "square face": .square, "strong jaw": .square, "angular": .square,
        "long face": .long, "narrow face": .long,
        "heart shaped": .heart, "heart-shaped": .heart
    ]

    private let skinToneKeywords: [String: SkinTone] = [
        "pale": .light, "fair skin": .light, "light skin": .light,
        "medium skin": .medium, "olive": .medium,
        "tan": .tan, "tanned": .tan,
        "dark skin": .dark, "deep skin": .dark
    ]

    // Countries and regions for origin extraction
    private let originKeywords: [String] = [
        "colombia", "colombian", "guatemala", "guatemalan", "mexico", "mexican",
        "brazil", "brazilian", "argentina", "argentine", "peru", "peruvian",
        "chile", "chilean", "venezuela", "venezuelan", "ecuador", "ecuadorian",
        "spain", "spanish", "france", "french", "germany", "german",
        "italy", "italian", "ireland", "irish", "england", "english", "british",
        "scotland", "scottish", "poland", "polish", "russia", "russian",
        "ukraine", "ukrainian", "china", "chinese", "japan", "japanese",
        "korea", "korean", "india", "indian", "vietnam", "vietnamese",
        "thailand", "thai", "philippines", "filipino", "filipina",
        "nigeria", "nigerian", "kenya", "kenyan", "ethiopia", "ethiopian",
        "egypt", "egyptian", "morocco", "moroccan", "south africa", "south african",
        "iran", "iranian", "persian", "turkey", "turkish", "israel", "israeli",
        "canada", "canadian", "australia", "australian", "new zealand"
    ]

    // Additional descriptive keywords
    private let descriptiveKeywords: [String] = [
        "tall", "short", "average height", "slim", "thin", "heavy", "stocky",
        "athletic", "muscular", "petite", "large", "broad shoulders",
        "friendly", "serious", "warm smile", "friendly smile", "bright smile",
        "kind eyes", "intense", "gentle", "quiet", "loud", "energetic",
        "handsome", "beautiful", "attractive", "pretty", "cute"
    ]

    // MARK: - Public Methods

    func extractKeywords(from transcript: String) -> [String] {
        let lowercased = transcript.lowercased()
        var keywords: [String] = []

        // Check for all known phrases
        let allPhrases = Array(hairColorKeywords.keys) +
                         Array(hairStyleKeywords.keys) +
                         Array(glassesKeywords.keys) +
                         Array(facialHairKeywords.keys) +
                         Array(ageKeywords.keys) +
                         Array(faceShapeKeywords.keys) +
                         Array(skinToneKeywords.keys)

        for phrase in allPhrases {
            if lowercased.contains(phrase) {
                keywords.append(phrase)
            }
        }

        // Extract origin/nationality
        for origin in originKeywords {
            if lowercased.contains(origin) {
                keywords.append("from \(origin)")
                break // Only include first match
            }
        }

        // Extract descriptive keywords
        for descriptor in descriptiveKeywords {
            if lowercased.contains(descriptor) {
                keywords.append(descriptor)
            }
        }

        return keywords
    }

    func parse(_ keywords: [String]) -> SketchFeatures {
        var features = SketchFeatures.default

        for keyword in keywords {
            let lower = keyword.lowercased()

            // Hair color
            for (phrase, color) in hairColorKeywords {
                if lower.contains(phrase) {
                    features.hairColor = color
                }
            }

            // Hair style
            for (phrase, style) in hairStyleKeywords {
                if lower.contains(phrase) {
                    features.hairStyle = style
                }
            }

            // Glasses
            for (phrase, style) in glassesKeywords {
                if lower.contains(phrase) {
                    features.hasGlasses = true
                    features.glassesStyle = style
                }
            }

            // Facial hair
            for (phrase, style) in facialHairKeywords {
                if lower.contains(phrase) {
                    features.hasFacialHair = true
                    features.facialHairStyle = style
                }
            }

            // Age
            for (phrase, age) in ageKeywords {
                if lower.contains(phrase) {
                    features.ageRange = age
                }
            }

            // Face shape
            for (phrase, shape) in faceShapeKeywords {
                if lower.contains(phrase) {
                    features.faceShape = shape
                }
            }

            // Skin tone
            for (phrase, tone) in skinToneKeywords {
                if lower.contains(phrase) {
                    features.skinTone = tone
                }
            }
        }

        return features
    }
}
