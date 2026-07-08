import SwiftUI

struct FieldPostcardReviewView: View {
    @Environment(BiomeAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let draft: ObservationDraft

    var quest: QuestCard { model.quest(for: draft.questId) ?? QuestCard.seedQuests[0] }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                postcard
                if let inlineError = model.inlineError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(inlineError)
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("Retry save or export text manually. Your draft is still here.")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                }
                Button("Saved to your trail") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(quest.habitatTag.color)
                    .accessibilityIdentifier("save-postcard-button")
                Button("Keep editing") { dismiss() }
            }
            .padding()
        }
        .background(BiomeTheme.paper.opacity(0.55))
        .navigationTitle("Field Postcard Review")
    }

    private var postcard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HabitatGlyph(habitat: quest.habitatTag)
                VStack(alignment: .leading) {
                    Text(quest.title)
                        .font(.title2.bold())
                    Text(quest.habitatTag.title.uppercased())
                        .font(.caption.weight(.black))
                        .foregroundStyle(quest.habitatTag.color)
                }
                Spacer()
                Text("FIELD POSTCARD")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
            RoundedRectangle(cornerRadius: 20)
                .fill(quest.habitatTag.color.opacity(0.16))
                .frame(height: 150)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: draft.photoLocalIdentifier == nil ? quest.habitatTag.glyph : "photo")
                            .font(.system(size: 44, weight: .semibold))
                        Text(draft.photoLocalIdentifier == nil ? "Illustrated habitat slot" : "Local photo reference")
                            .font(.caption)
                    }
                    .foregroundStyle(quest.habitatTag.color)
                }
            labeledLine("Place", draft.placeClue)
            labeledLine("Discovery", draft.discoverySentence)
            tagWrap(title: "Texture", tags: draft.textureTags)
            tagWrap(title: "Color", tags: draft.colorTags)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.88))
                .shadow(color: BiomeTheme.soil.opacity(0.18), radius: 18, x: 0, y: 10)
        )
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(quest.habitatTag.color.opacity(0.24), lineWidth: 2))
        .accessibilityLabel("Field postcard preview for \(quest.title)")
    }

    private func labeledLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(value.isEmpty ? "Not added yet" : value).font(.body)
        }
    }

    private func tagWrap(title: String, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            FlowWrap(items: tags.isEmpty ? ["editable later"] : tags) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(BiomeTheme.paper, in: Capsule())
            }
        }
    }

    private func save() {
        if model.savePostcard(from: draft) {
            dismiss()
        }
    }
}

struct FlowWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
