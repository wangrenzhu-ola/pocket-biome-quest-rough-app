import Foundation

struct CueSuggestion: Equatable {
    var textureTags: [String]
    var colorTags: [String]
    var explanation: String
}

struct CueAssistant {
    func suggest(placeClue: String, discoverySentence: String, habitat: HabitatTag) -> CueSuggestion {
        let text = "\(placeClue) \(discoverySentence)".lowercased()
        var textures: [String] = []
        var colors: [String] = []

        if text.contains("wet") || habitat == .puddle { textures.append("glossy edge"); colors.append("sky blue") }
        if text.contains("rough") || habitat == .bark { textures.append("ridged"); colors.append("soil brown") }
        if text.contains("soft") || habitat == .moss { textures.append("velvet patch"); colors.append("lichen green") }
        if text.contains("flower") || habitat == .pollinator { textures.append("hovering motion"); colors.append("pollen gold") }
        if text.contains("crack") || habitat == .stone { textures.append("tiny fissures"); colors.append("stone gray") }
        if textures.isEmpty { textures.append(contentsOf: ["tiny pattern", "street-side clue"]) }
        if colors.isEmpty { colors.append(contentsOf: ["sage green", "warm tan"]) }

        return CueSuggestion(
            textureTags: Array(textures.prefix(3)),
            colorTags: Array(colors.prefix(3)),
            explanation: "Local cue only. Edit or skip these chips before saving."
        )
    }
}
