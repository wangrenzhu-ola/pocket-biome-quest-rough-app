import Foundation

enum BiomeStoreError: LocalizedError {
    case simulatedWriteFailure
    case readFailed

    var errorDescription: String? {
        switch self {
        case .simulatedWriteFailure: "Couldn’t save this postcard. Your draft is still here."
        case .readFailed: "The trail archive could not be read. Try again from the Quest Deck."
        }
    }
}

struct BiomeSnapshot: Codable, Equatable {
    var postcards: [FieldPostcard]
    var drafts: [ObservationDraft]
    var privacy: PrivacyPreference
    var premiumPacks: [PremiumPackState]
    var trailPlans: [TrailPlan]

    init(
        postcards: [FieldPostcard],
        drafts: [ObservationDraft],
        privacy: PrivacyPreference,
        premiumPacks: [PremiumPackState],
        trailPlans: [TrailPlan] = []
    ) {
        self.postcards = postcards
        self.drafts = drafts
        self.privacy = privacy
        self.premiumPacks = premiumPacks
        self.trailPlans = trailPlans
    }

    private enum CodingKeys: String, CodingKey {
        case postcards
        case drafts
        case privacy
        case premiumPacks
        case trailPlans
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postcards = try container.decodeIfPresent([FieldPostcard].self, forKey: .postcards) ?? []
        drafts = try container.decodeIfPresent([ObservationDraft].self, forKey: .drafts) ?? []
        privacy = try container.decodeIfPresent(PrivacyPreference.self, forKey: .privacy) ?? .defaultValue
        premiumPacks = try container.decodeIfPresent([PremiumPackState].self, forKey: .premiumPacks) ?? PremiumQuestStore.defaultPacks
        trailPlans = try container.decodeIfPresent([TrailPlan].self, forKey: .trailPlans) ?? []
    }
}

final class BiomeStore {
    private let fileURL: URL
    var simulateNextSaveFailure = false

    init(directory: URL? = nil) {
        let baseDirectory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = baseDirectory.appendingPathComponent("PocketBiomeQuest", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        fileURL = appDirectory.appendingPathComponent("biome-trail.json")
    }

    func load() throws -> BiomeSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return BiomeSnapshot(postcards: [], drafts: [], privacy: .defaultValue, premiumPacks: PremiumQuestStore.defaultPacks, trailPlans: [])
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.biome.decode(BiomeSnapshot.self, from: data)
    }

    func save(_ snapshot: BiomeSnapshot) throws {
        if simulateNextSaveFailure {
            simulateNextSaveFailure = false
            throw BiomeStoreError.simulatedWriteFailure
        }
        let data = try JSONEncoder.biome.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}

extension JSONEncoder {
    static var biome: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var biome: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
