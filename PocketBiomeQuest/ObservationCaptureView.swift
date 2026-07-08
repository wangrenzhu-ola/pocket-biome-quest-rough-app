import SwiftUI

struct ObservationCaptureView: View {
    @Environment(BiomeAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let quest: QuestCard

    @State private var draft: ObservationDraft
    @State private var reviewDraft: ObservationDraft?
    @State private var showPhotoNotice = false
    @State private var suggestionsApplied = false

    private let textureOptions = ["velvet patch", "ridged", "glossy edge", "tiny fissures", "hovering motion", "street-side clue"]
    private let colorOptions = ["lichen green", "soil brown", "pollen gold", "sky blue", "stone gray", "warm tan"]

    init(quest: QuestCard) {
        self.quest = quest
        _draft = State(initialValue: ObservationDraft(id: UUID(), questId: quest.id, placeClue: "", textureTags: [], colorTags: [], discoverySentence: "", photoLocalIdentifier: nil, createdAt: Date(), updatedAt: Date()))
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    HabitatGlyph(habitat: quest.habitatTag)
                    VStack(alignment: .leading) {
                        Text(quest.title).font(.headline)
                        Text(quest.prompt).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Text(draft.progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(quest.habitatTag.color)
            } header: {
                Text("Build this field postcard")
            }

            Section("Place clue") {
                TextField("Example: north curb under the bakery window", text: $draft.placeClue, axis: .vertical)
                    .accessibilityLabel("Place clue")
            }

            chipSection(title: "Texture tags", options: textureOptions, selection: $draft.textureTags)
            chipSection(title: "Color tags", options: colorOptions, selection: $draft.colorTags)

            Section("Discovery sentence") {
                TextField("I noticed...", text: $draft.discoverySentence, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityLabel("Discovery sentence")
            }

            Section("Local cue assistant") {
                Text("Suggestions stay on this device. They are optional, editable, and confirmed only when you save.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Suggest editable chips", action: applySuggestion)
                if suggestionsApplied {
                    Text("Editable local cue chips added. Remove any chip before saving if it does not match your walk.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Photo slot") {
                Button("Add optional photo placeholder") { showPhotoNotice = true }
                Text("Photo access is optional. Pocket Biome Quest stores only local photo references and never uploads observations.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let inlineError = model.inlineError {
                Section {
                    Text(inlineError)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.red)
                    Button("Retry save") { reviewDraft = draft }
                    Button("Export text manually") { }
                }
            }

            Section {
                Button("Save draft") { model.saveDraft(draft) }
                Button("Preview field postcard") { reviewDraft = draft }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canPreview)
                Button("Simulate save failure") { model.simulateNextSaveFailureForRecoveryDemo() }
                    .font(.caption)
            }
        }
        .navigationTitle("Observation Capture")
        .navigationDestination(item: $reviewDraft) { draft in
            FieldPostcardReviewView(draft: draft)
        }
        .alert("Photo permission", isPresented: $showPhotoNotice) {
            Button("Not now", role: .cancel) { }
            Button("Use local reference") { draft.photoLocalIdentifier = "local-photo-placeholder" }
        } message: {
            Text("Photo access is optional. If permission is unavailable, finish the postcard with words and chips.")
        }
    }

    private var canPreview: Bool {
        !draft.placeClue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draft.discoverySentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func applySuggestion() {
        let suggestion = model.cueSuggestion(for: draft)
        draft.textureTags = Array(Set(draft.textureTags + suggestion.textureTags)).sorted()
        draft.colorTags = Array(Set(draft.colorTags + suggestion.colorTags)).sorted()
        suggestionsApplied = true
    }

    private func chipSection(title: String, options: [String], selection: Binding<[String]>) -> some View {
        Section(title) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChipView(title: option, isSelected: selection.wrappedValue.contains(option)) {
                        toggle(option, in: selection)
                    }
                }
            }
        }
    }

    private func toggle(_ option: String, in selection: Binding<[String]>) {
        if selection.wrappedValue.contains(option) {
            selection.wrappedValue.removeAll { $0 == option }
        } else {
            selection.wrappedValue.append(option)
        }
    }
}
