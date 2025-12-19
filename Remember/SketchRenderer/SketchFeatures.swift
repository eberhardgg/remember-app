import Foundation

/// Extracted visual features from a voice description
struct SketchFeatures {
    var hairColor: HairColor?
    var hairStyle: HairStyle?
    var hasGlasses: Bool
    var glassesStyle: GlassesStyle?
    var hasFacialHair: Bool
    var facialHairStyle: FacialHairStyle?
    var ageRange: AgeRange?
    var faceShape: FaceShape?
    var skinTone: SkinTone?
    var accessories: [Accessory]

    static let `default` = SketchFeatures(
        hairColor: nil,
        hairStyle: nil,
        hasGlasses: false,
        glassesStyle: nil,
        hasFacialHair: false,
        facialHairStyle: nil,
        ageRange: nil,
        faceShape: nil,
        skinTone: nil,
        accessories: []
    )
}

enum HairColor: String, CaseIterable {
    case black
    case brown
    case blonde
    case red
    case gray
    case white
    case auburn
}

enum HairStyle: String, CaseIterable {
    case short
    case long
    case curly
    case straight
    case wavy
    case bald
    case ponytail
    case bun
    case buzzCut
    case mohawk
}

enum GlassesStyle: String, CaseIterable {
    case round
    case square
    case rectangular
    case aviator
}

enum FacialHairStyle: String, CaseIterable {
    case beard
    case goatee
    case mustache
    case stubble
    case soulPatch
}

enum AgeRange: String, CaseIterable {
    case young      // 18-30
    case middle     // 30-50
    case older      // 50+
}

enum FaceShape: String, CaseIterable {
    case round
    case oval
    case square
    case long
    case heart
}

enum SkinTone: String, CaseIterable {
    case light
    case medium
    case tan
    case dark
}

enum Accessory: String, CaseIterable {
    case hat
    case earrings
    case necklace
    case bowtie
    case tie
}
