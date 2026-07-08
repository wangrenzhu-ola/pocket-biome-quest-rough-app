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
    var trailPlans: [TrailPlan] = []
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
            trailPlans = snapshot.trailPlans
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

    func rolePrompt(for quest: QuestCard) -> QuestRolePrompt {
        QuestRolePrompt(
            spotterPrompt: "Spotter prompt: find one \(quest.habitatTag.title.lowercased()) clue before anyone names a species.",
            storytellerPrompt: "Storyteller prompt: describe the texture, color, edge, motion, or sound in one field postcard sentence."
        )
    }

    func createTrailPlan(minutes: Int) -> TrailPlan {
        let freeQuests = quests.filter { !$0.isPremium }
        let selectedQuests = Array(freeQuests.prefix(3))
        let plan = TrailPlan(
            id: UUID(),
            title: "\(minutes)-minute micro-safari",
            estimatedMinutes: minutes,
            questIds: selectedQuests.map(\.id),
            habitatMix: selectedQuests.map(\.habitatTag),
            createdAt: Date(),
            completedQuestIds: []
        )
        trailPlans.insert(plan, at: 0)
        persist()
        return plan
    }

    func quests(for plan: TrailPlan) -> [QuestCard] {
        plan.questIds.compactMap { quest(for: $0) }
    }

    func completeQuest(_ quest: QuestCard, in plan: TrailPlan) {
        guard let index = trailPlans.firstIndex(where: { $0.id == plan.id }) else { return }
        if !trailPlans[index].completedQuestIds.contains(quest.id) {
            trailPlans[index].completedQuestIds.append(quest.id)
        }
        if persist() {
            successMessage = trailPlans[index].isComplete ? "Micro-safari trail plan complete" : "Next tiny stop is ready"
        }
    }

    func currentTrailPlan(matching plan: TrailPlan) -> TrailPlan {
        trailPlans.first { $0.id == plan.id } ?? plan
    }

    func currentAlmanacWeek(referenceDate: Date = Date()) -> AlmanacWeek {
        let calendar = Calendar(identifier: .iso8601)
        let week = calendar.component(.weekOfYear, from: referenceDate)
        let year = calendar.component(.yearForWeekOfYear, from: referenceDate)
        let id = "\(year)-W\(String(format: "%02d", week))"
        let currentWeekPostcards = postcards.filter {
            calendar.component(.weekOfYear, from: $0.savedAt) == week &&
            calendar.component(.yearForWeekOfYear, from: $0.savedAt) == year
        }
        let habitatCounts = Dictionary(grouping: currentWeekPostcards, by: \.habitatTag)
            .mapValues { $0.count }
        let colorSwatches = Array(Set(currentWeekPostcards.flatMap(\.colorTags))).sorted()
        let suggestedNextHabitats = HabitatTag.allCases.filter { habitatCounts[$0] == nil }

        return AlmanacWeek(
            id: id,
            postcardIds: currentWeekPostcards.map(\.id),
            habitatCounts: habitatCounts,
            colorSwatches: colorSwatches,
            suggestedNextHabitats: Array(suggestedNextHabitats.prefix(3))
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

    func purchasePremiumPack(_ pack: PremiumPackState) async {
        let updatedPack = await premiumStore.purchase(productId: pack.productId)
        upsertPremiumPack(updatedPack)
        persist()
    }

    func restorePremiumPacks() async {
        premiumPacks = await premiumStore.restorePurchases(currentPacks: premiumPacks)
        persist()
    }

    @discardableResult
    private func persist() -> Bool {
        do {
            try store.save(BiomeSnapshot(postcards: postcards, drafts: drafts, privacy: privacy, premiumPacks: premiumPacks, trailPlans: trailPlans))
            inlineError = nil
            return true
        } catch {
            inlineError = "Couldn’t save this postcard. Your draft is still here."
            return false
        }
    }

    private func upsertPremiumPack(_ pack: PremiumPackState) {
        if let index = premiumPacks.firstIndex(where: { $0.productId == pack.productId }) {
            premiumPacks[index] = pack
        } else {
            premiumPacks.append(pack)
        }
    }
}
