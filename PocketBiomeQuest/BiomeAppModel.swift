import Foundation
import Observation

@MainActor
@Observable
final class BiomeAppModel {
    enum AppTab: String, CaseIterable, Identifiable {
        case quests
        case archive
        case premium
        case privacy
        var id: String { rawValue }
    }

    var selectedTab: AppTab = .quests
    var quests: [QuestCard] = QuestCard.seedQuests
    var postcards: [FieldPostcard] = []
    var drafts: [ObservationDraft] = []
    var privacy: PrivacyPreference = .defaultValue
    var premiumPacks: [PremiumPackState] = PremiumQuestStore.defaultPacks
    var inlineError: String?
    var successMessage: String?
    var archiveFilter: HabitatTag?

    private let store: BiomeStore
    private let cueAssistant = CueAssistant()
    private let premiumStore = PremiumQuestStore()

    init(store: BiomeStore = BiomeStore()) {
        self.store = store
        loadSnapshot()
    }

    var filteredPostcards: [FieldPostcard] {
        postcards
            .filter { archiveFilter == nil || $0.habitatTag == archiveFilter }
            .sorted { $0.savedAt > $1.savedAt }
    }

    func loadSnapshot() {
        do {
            let snapshot = try store.load()
            postcards = snapshot.postcards
            drafts = snapshot.drafts
            privacy = snapshot.privacy
            premiumPacks = snapshot.premiumPacks.isEmpty ? PremiumQuestStore.defaultPacks : snapshot.premiumPacks
            inlineError = nil
        } catch {
            inlineError = "The trail archive could not be read. Try again from the Quest Deck."
        }
    }

    func acknowledgePrivacy(localOnly: Bool, diagnosticsOptIn: Bool) {
        privacy.localOnlyAcknowledged = localOnly
        privacy.diagnosticsOptIn = diagnosticsOptIn
        persist()
    }

    func startDraft(for quest: QuestCard) -> ObservationDraft {
        ObservationDraft(
            id: UUID(),
            questId: quest.id,
            placeClue: "",
            textureTags: [],
            colorTags: [],
            discoverySentence: "",
            photoLocalIdentifier: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func quest(for id: UUID) -> QuestCard? {
        quests.first { $0.id == id }
    }

    func cueSuggestion(for draft: ObservationDraft) -> CueSuggestion {
        cueAssistant.suggest(
            placeClue: draft.placeClue,
            discoverySentence: draft.discoverySentence,
            habitat: quest(for: draft.questId)?.habitatTag ?? .moss
        )
    }

    func saveDraft(_ draft: ObservationDraft) {
        var updatedDraft = draft
        updatedDraft.updatedAt = Date()
        drafts.removeAll { $0.id == draft.id }
        drafts.append(updatedDraft)
        persist()
    }

    func savePostcard(from draft: ObservationDraft, style: String = "Field notebook postcard") -> Bool {
        guard let quest = quest(for: draft.questId) else {
            inlineError = "Choose a quest before building this field postcard."
            return false
        }
        let postcard = FieldPostcard(
            id: UUID(),
            questId: quest.id,
            questTitle: quest.title,
            placeClue: draft.placeClue.trimmingCharacters(in: .whitespacesAndNewlines),
            textureTags: draft.textureTags,
            colorTags: draft.colorTags,
            discoverySentence: draft.discoverySentence.trimmingCharacters(in: .whitespacesAndNewlines),
            photoLocalIdentifier: draft.photoLocalIdentifier,
            habitatTag: quest.habitatTag,
            postcardStyle: style,
            savedAt: Date(),
            editedAt: Date()
        )
        postcards.insert(postcard, at: 0)
        drafts.removeAll { $0.id == draft.id }
        if persist() {
            successMessage = "Saved to your trail"
            selectedTab = .archive
            return true
        }
        postcards.removeAll { $0.id == postcard.id }
        return false
    }

    func updatePostcard(_ postcard: FieldPostcard) {
        guard let index = postcards.firstIndex(where: { $0.id == postcard.id }) else { return }
        var edited = postcard
        edited.editedAt = Date()
        postcards[index] = edited
        if persist() {
            successMessage = "Update postcard"
        }
    }

    func deletePostcard(_ postcard: FieldPostcard) {
        postcards.removeAll { $0.id == postcard.id }
        if persist() {
            successMessage = "Field postcard deleted"
        }
    }

    func simulateNextSaveFailureForRecoveryDemo() {
        store.simulateNextSaveFailure = true
    }

    func refreshPremiumPacks() async {
        premiumPacks = await premiumStore.loadProducts()
        persist()
    }

    @discardableResult
    private func persist() -> Bool {
        do {
            try store.save(BiomeSnapshot(postcards: postcards, drafts: drafts, privacy: privacy, premiumPacks: premiumPacks))
            inlineError = nil
            return true
        } catch {
            inlineError = "Couldn’t save this postcard. Your draft is still here."
            return false
        }
    }
}
