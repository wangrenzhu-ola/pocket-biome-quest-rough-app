import Foundation
import SwiftUI

enum HabitatTag: String, Codable, CaseIterable, Identifiable {
    case moss
    case bark
    case pollinator
    case puddle
    case stone
    case weed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moss: "Moss"
        case .bark: "Bark"
        case .pollinator: "Pollinator"
        case .puddle: "Puddle"
        case .stone: "Stone"
        case .weed: "Weed"
        }
    }

    var glyph: String {
        switch self {
        case .moss: "leaf.fill"
        case .bark: "tree.fill"
        case .pollinator: "ladybug.fill"
        case .puddle: "drop.fill"
        case .stone: "circle.hexagongrid.fill"
        case .weed: "camera.macro"
        }
    }

    var color: Color {
        switch self {
        case .moss: Color(red: 0.36, green: 0.54, blue: 0.34)
        case .bark: Color(red: 0.48, green: 0.32, blue: 0.22)
        case .pollinator: Color(red: 0.83, green: 0.61, blue: 0.21)
        case .puddle: Color(red: 0.36, green: 0.58, blue: 0.76)
        case .stone: Color(red: 0.45, green: 0.46, blue: 0.42)
        case .weed: Color(red: 0.43, green: 0.62, blue: 0.30)
        }
    }
}

struct QuestCard: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var habitatTag: HabitatTag
    var prompt: String
    var actionVerb: String
    var estimatedMinutes: Int
    var visualGlyph: String
    var premiumPackId: String?

    var isPremium: Bool { premiumPackId != nil }
}

struct ObservationDraft: Identifiable, Codable, Equatable {
    var id: UUID
    var questId: UUID
    var placeClue: String
    var textureTags: [String]
    var colorTags: [String]
    var discoverySentence: String
    var photoLocalIdentifier: String?
    var createdAt: Date
    var updatedAt: Date

    var progressText: String {
        let count = [!placeClue.isEmpty, !textureTags.isEmpty, !colorTags.isEmpty, !discoverySentence.isEmpty].filter { $0 }.count
        return "\(count) of 4 postcard clues ready"
    }
}

struct FieldPostcard: Identifiable, Codable, Equatable {
    var id: UUID
    var questId: UUID
    var questTitle: String
    var placeClue: String
    var textureTags: [String]
    var colorTags: [String]
    var discoverySentence: String
    var photoLocalIdentifier: String?
    var habitatTag: HabitatTag
    var postcardStyle: String
    var savedAt: Date
    var editedAt: Date
}

enum EntitlementState: String, Codable, Equatable {
    case locked
    case purchased
    case unavailable
    case restoring
}

struct PremiumPackState: Identifiable, Codable, Equatable {
    var id: String { productId }
    var productId: String
    var displayName: String
    var entitlementState: EntitlementState
    var storeKitAvailability: String
    var restoreState: String
}

struct PrivacyPreference: Codable, Equatable {
    var photoAccessStatus: String
    var localOnlyAcknowledged: Bool
    var diagnosticsOptIn: Bool

    static let defaultValue = PrivacyPreference(
        photoAccessStatus: "not_requested",
        localOnlyAcknowledged: false,
        diagnosticsOptIn: false
    )
}

extension QuestCard {
    static let seedQuests: [QuestCard] = [
        QuestCard(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, title: "Find a moss color gradient", habitatTag: .moss, prompt: "Look along a wall, curb, or tree base for three shades of green.", actionVerb: "Notice", estimatedMinutes: 8, visualGlyph: "leaf.fill", premiumPackId: nil),
        QuestCard(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, title: "Trace bark texture like a map", habitatTag: .bark, prompt: "Choose one tree and describe the ridges, cracks, and warm shadows.", actionVerb: "Trace", estimatedMinutes: 6, visualGlyph: "tree.fill", premiumPackId: nil),
        QuestCard(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, title: "Pause for pollinator motion", habitatTag: .pollinator, prompt: "Watch one flower patch for tiny wings, hovering, or landing patterns.", actionVerb: "Pause", estimatedMinutes: 10, visualGlyph: "ladybug.fill", premiumPackId: nil),
        QuestCard(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, title: "Scan a puddle edge", habitatTag: .puddle, prompt: "Find reflections, grit, or leaf shapes gathered along a wet edge.", actionVerb: "Scan", estimatedMinutes: 5, visualGlyph: "drop.fill", premiumPackId: nil),
        QuestCard(id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, title: "Winter lichen lookout", habitatTag: .stone, prompt: "A premium seasonal quest for pale circles on stone, brick, or old railings.", actionVerb: "Look", estimatedMinutes: 9, visualGlyph: "circle.hexagongrid.fill", premiumPackId: "pocketbiome.seasonal.lichen")
    ]
}
