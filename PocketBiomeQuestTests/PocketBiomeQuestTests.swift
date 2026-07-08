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

    private func tempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
