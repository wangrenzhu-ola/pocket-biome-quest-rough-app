import SwiftUI

struct TrailArchiveView: View {
    @Environment(BiomeAppModel.self) private var model

    var body: some View {
        Group {
            if model.filteredPostcards.isEmpty {
                emptyTrail
            } else {
                List {
                    filterSection
                    ForEach(model.filteredPostcards) { postcard in
                        NavigationLink {
                            PostcardDetailView(postcard: postcard)
                        } label: {
                            PostcardRow(postcard: postcard)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Trail Archive")
        .toolbar {
            Button("Quest Deck") { model.selectedTab = .quests }
        }
    }

    private var filterSection: some View {
        Section("Habitat filter") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ChipView(title: "All", isSelected: model.archiveFilter == nil) { model.archiveFilter = nil }
                    ForEach(HabitatTag.allCases) { tag in
                        ChipView(title: tag.title, isSelected: model.archiveFilter == tag) { model.archiveFilter = tag }
                    }
                }
            }
        }
    }

    private var emptyTrail: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(BiomeTheme.paper)
                    .frame(width: 240, height: 180)
                    .overlay(RoundedRectangle(cornerRadius: 34).stroke(style: StrokeStyle(lineWidth: 2, dash: [7])))
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 56))
                    Text("Blank field notebook trail")
                        .font(.headline)
                }
                .foregroundStyle(BiomeTheme.soil)
            }
            Text("Start your first micro-safari")
                .font(.title2.bold())
            Text("Choose a quest, notice a tiny sidewalk habitat, and save the moment as a field postcard.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Quest Deck") { model.selectedTab = .quests }
                .buttonStyle(.borderedProminent)
                .tint(BiomeTheme.soil)
            Spacer()
        }
        .padding()
        .accessibilityLabel("Empty trail archive. Start your first micro-safari.")
    }
}

struct PostcardRow: View {
    let postcard: FieldPostcard

    var body: some View {
        HStack(spacing: 14) {
            HabitatGlyph(habitat: postcard.habitatTag)
            VStack(alignment: .leading, spacing: 4) {
                Text(postcard.questTitle).font(.headline)
                Text(postcard.discoverySentence).lineLimit(2).font(.subheadline).foregroundStyle(.secondary)
                Text(postcard.savedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Saved postcard for \(postcard.questTitle)")
    }
}
