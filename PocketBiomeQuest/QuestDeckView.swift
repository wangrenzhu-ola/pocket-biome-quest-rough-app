import SwiftUI

struct QuestDeckView: View {
    @Environment(BiomeAppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroHeader
                ForEach(model.quests) { quest in
                    NavigationLink(value: quest) {
                        QuestCardView(quest: quest, isLocked: quest.isPremium)
                    }
                    .buttonStyle(.plain)
                    .disabled(quest.isPremium)
                }
                NavigationLink("Explore Premium Quest Packs") {
                    PremiumPacksView()
                }
                .buttonStyle(.borderedProminent)
                .tint(BiomeTheme.soil)
            }
            .padding()
        }
        .background(BiomeTheme.paper.opacity(0.42))
        .navigationTitle("Choose a micro-biome quest")
        .navigationDestination(for: QuestCard.self) { quest in
            ObservationCaptureView(quest: quest)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(BiomeTheme.habitatGradient)
                    .frame(height: 190)
                    .overlay(alignment: .topTrailing) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.macro")
                            Image(systemName: "leaf.fill")
                            Image(systemName: "drop.fill")
                        }
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.84))
                        .padding(24)
                    }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sidewalk micro-safari")
                        .font(.title.bold())
                    Text("Pick one tiny habitat, notice it closely, then turn the clue into a field postcard.")
                        .font(.body)
                }
                .foregroundStyle(BiomeTheme.ink)
                .padding(20)
            }
            Text("Free quests always work locally. No species certainty, no online community, no account.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sidewalk micro-safari hero image slot")
    }
}

struct QuestCardView: View {
    let quest: QuestCard
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            HabitatGlyph(habitat: quest.habitatTag)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(quest.actionVerb.uppercased())
                        .font(.caption.weight(.black))
                        .foregroundStyle(quest.habitatTag.color)
                    Text("\(quest.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(quest.title)
                    .font(.headline)
                    .foregroundStyle(BiomeTheme.ink)
                Text(quest.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .foregroundStyle(isLocked ? .secondary : quest.habitatTag.color)
        }
        .padding(16)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(quest.habitatTag.color.opacity(0.28)))
        .accessibilityLabel("Quest card: \(quest.title), \(quest.habitatTag.title), \(quest.estimatedMinutes) minutes")
    }
}
