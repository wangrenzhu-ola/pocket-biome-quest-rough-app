import XCTest
@testable import PocketBiomeQuest

@MainActor
final class PocketBiomeQuestTests: XCTestCase {
    func testCreateUpdateDeleteFieldPostcard() throws {
        let model = BiomeAppModel(store: BiomeStore(directory: tempDirectory()))
        let quest = QuestCard.seedQuests[0]
        var draft = model.startDraft(for: quest)
        draft.placeClue = "north curb under the bakery window"
        draft.textureTags = ["velvet patch"]
        draft.colorTags = ["lichen green"]
        draft.discoverySentence = "I noticed three greens tucked into one moss edge."

        XCTAssertTrue(model.savePostcard(from: draft))
        XCTAssertEqual(model.postcards.count, 1)
        XCTAssertEqual(model.postcards[0].habitatTag, .moss)

        var edited = model.postcards[0]
        edited.discoverySentence = "I noticed a brighter green stripe near the curb."
        model.updatePostcard(edited)
        XCTAssertEqual(model.postcards[0].discoverySentence, "I noticed a brighter green stripe near the curb.")

        model.deletePostcard(model.postcards[0])
        XCTAssertTrue(model.postcards.isEmpty)
    }

    func testPersistenceSurvivesRelaunch() throws {
        let directory = tempDirectory()
        let firstLaunch = BiomeAppModel(store: BiomeStore(directory: directory))
        let quest = QuestCard.seedQuests[1]
        var draft = firstLaunch.startDraft(for: quest)
        draft.placeClue = "old sycamore beside the school gate"
        draft.textureTags = ["ridged"]
        draft.colorTags = ["soil brown"]
        draft.discoverySentence = "The bark looked like a tiny street map."
        XCTAssertTrue(firstLaunch.savePostcard(from: draft))

        let relaunch = BiomeAppModel(store: BiomeStore(directory: directory))
        XCTAssertEqual(relaunch.postcards.count, 1)
        XCTAssertEqual(relaunch.postcards[0].placeClue, "old sycamore beside the school gate")
    }

    func testSaveFailureKeepsDraftRecoverable() throws {
        let store = BiomeStore(directory: tempDirectory())
        let model = BiomeAppModel(store: store)
        var draft = model.startDraft(for: QuestCard.seedQuests[2])
        draft.placeClue = "flower box outside the train stop"
        draft.textureTags = ["hovering motion"]
        draft.colorTags = ["pollen gold"]
        draft.discoverySentence = "One tiny wing paused over the yellow flower."

        model.simulateNextSaveFailureForRecoveryDemo()
        XCTAssertFalse(model.savePostcard(from: draft))
        XCTAssertEqual(model.inlineError, "Couldn’t save this postcard. Your draft is still here.")
        XCTAssertTrue(model.postcards.isEmpty)
    }

    func testCueAssistantSuggestionsAreLocalEditableHints() {
        let assistant = CueAssistant()
        let suggestion = assistant.suggest(placeClue: "wet curb", discoverySentence: "The puddle edge reflected sky", habitat: .puddle)
        XCTAssertTrue(suggestion.textureTags.contains("glossy edge"))
        XCTAssertTrue(suggestion.colorTags.contains("sky blue"))
        XCTAssertTrue(suggestion.explanation.contains("Edit or skip"))
    }

    func testPremiumAndPrivacyDefaults() {
        XCTAssertEqual(PremiumQuestStore.productIds, ["pocketbiome.seasonal.lichen", "pocketbiome.spring.pollinators"])
        XCTAssertEqual(PremiumQuestStore.defaultPacks.first?.entitlementState, .unavailable)
        XCTAssertFalse(PrivacyPreference.defaultValue.localOnlyAcknowledged)
    }

    func testTrailPlanCreationCompletionAndPersistence() throws {
        let directory = tempDirectory()
        let model = BiomeAppModel(store: BiomeStore(directory: directory))

        let plan = model.createTrailPlan(minutes: 15)

        XCTAssertEqual(plan.estimatedMinutes, 15)
        XCTAssertEqual(plan.questIds.count, 3)
        XCTAssertEqual(plan.habitatMix.count, 3)
        XCTAssertTrue(model.quests(for: plan).allSatisfy { !$0.isPremium })

        let firstQuest = model.quests(for: plan)[0]
        model.completeQuest(firstQuest, in: plan)
        XCTAssertTrue(model.currentTrailPlan(matching: plan).containsCompletedQuest(firstQuest.id))

        let relaunch = BiomeAppModel(store: BiomeStore(directory: directory))
        XCTAssertEqual(relaunch.trailPlans.count, 1)
        XCTAssertTrue(relaunch.currentTrailPlan(matching: plan).containsCompletedQuest(firstQuest.id))
    }

    func testAlmanacWeekSummarizesPostcardsAndSuggestsNextHabitats() throws {
        let model = BiomeAppModel(store: BiomeStore(directory: tempDirectory()))
        var mossDraft = model.startDraft(for: QuestCard.seedQuests[0])
        mossDraft.placeClue = "stone wall by the bus stop"
        mossDraft.textureTags = ["velvet patch"]
        mossDraft.colorTags = ["lichen green"]
        mossDraft.discoverySentence = "The moss made three soft greens."
        XCTAssertTrue(model.savePostcard(from: mossDraft))

        var barkDraft = model.startDraft(for: QuestCard.seedQuests[1])
        barkDraft.placeClue = "sycamore at the corner"
        barkDraft.textureTags = ["ridged"]
        barkDraft.colorTags = ["soil brown"]
        barkDraft.discoverySentence = "The bark looked like a small map."
        XCTAssertTrue(model.savePostcard(from: barkDraft))

        let almanac = model.currentAlmanacWeek()
        XCTAssertEqual(almanac.postcardCount, 2)
        XCTAssertEqual(almanac.habitatCounts[.moss], 1)
        XCTAssertEqual(almanac.habitatCounts[.bark], 1)
        XCTAssertTrue(almanac.colorSwatches.contains("lichen green"))
        XCTAssertTrue(almanac.suggestedNextHabitats.contains(.pollinator))
    }

    func testTwoPersonRolePromptsStayLocalAndNonSpeciesSpecific() {
        let model = BiomeAppModel(store: BiomeStore(directory: tempDirectory()))
        let prompt = model.rolePrompt(for: QuestCard.seedQuests[0])

        XCTAssertTrue(prompt.spotterPrompt.contains("Spotter prompt"))
        XCTAssertTrue(prompt.storytellerPrompt.contains("Storyteller prompt"))
        XCTAssertTrue(prompt.spotterPrompt.contains("before anyone names a species"))
        XCTAssertFalse(prompt.spotterPrompt.localizedCaseInsensitiveContains("account"))
        XCTAssertFalse(prompt.storytellerPrompt.localizedCaseInsensitiveContains("community"))
    }

    func testSeasonalPackPreviewAndFreeCoreAvailability() {
        let model = BiomeAppModel(store: BiomeStore(directory: tempDirectory()))
        let preview = SeasonalPackPreview.preview(for: "pocketbiome.seasonal.lichen")

        XCTAssertEqual(preview.sampleChain.count, 3)
        XCTAssertTrue(preview.caption.contains("Free quests stay open"))
        XCTAssertGreaterThanOrEqual(model.quests.filter { !$0.isPremium }.count, 3)
        XCTAssertTrue(PremiumQuestStore.defaultPacks.allSatisfy { $0.entitlementState == .unavailable })
    }

    private func tempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
