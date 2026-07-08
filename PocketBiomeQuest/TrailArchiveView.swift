import SwiftUI

struct TrailArchiveView: View {
    @Environment(BiomeAppModel.self) private var model

    var body: some View {
        Group {
            if model.postcards.isEmpty {
                emptyTrail
            } else {
                List {
                    almanacSection
                    filterSection
                    if model.filteredPostcards.isEmpty {
                        Text("No postcards match this habitat yet. Clear the filter or start another micro-safari.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.filteredPostcards) { postcard in
                            NavigationLink {
                                PostcardDetailView(postcard: postcard)
                            } label: {
                                PostcardRow(postcard: postcard)
                            }
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

    private var almanacSection: some View {
        let almanac = model.currentAlmanacWeek()
        return Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "books.vertical")
                        .foregroundStyle(BiomeTheme.soil)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("This week’s pocket almanac")
                            .font(.headline)
                        Text("\(almanac.postcardCount) saved postcards in \(almanac.id)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if !almanac.habitatCounts.isEmpty {
                    FlowWrap(items: Array(almanac.habitatCounts.keys).sorted { $0.title < $1.title }) { habitat in
                        Label("\(habitat.title) \(almanac.habitatCounts[habitat] ?? 0)", systemImage: habitat.glyph)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(habitat.color.opacity(0.14), in: Capsule())
                    }
                }
                if !almanac.colorSwatches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color palette")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                        FlowWrap(items: Array(almanac.colorSwatches.prefix(8))) { swatch in
                            Text(swatch)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(BiomeTheme.paper, in: Capsule())
                        }
                    }
                }
                if !almanac.suggestedNextHabitats.isEmpty {
                    Text("You have not explored \(almanac.suggestedNextHabitats.map { $0.title.lowercased() }.joined(separator: ", ")) yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("This week’s pocket almanac with habitat recap, color palette, and unexplored habitat prompts.")
        } header: {
            Text("Weekly Almanac")
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
            Button("Build a 15-minute micro-safari") { model.selectedTab = .quests }
                .font(.subheadline.weight(.semibold))
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
