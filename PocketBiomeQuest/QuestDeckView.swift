import SwiftUI

struct QuestDeckView: View {
    @Environment(BiomeAppModel.self) private var model
    @State private var trailPlanMinutes = 15
    @State private var activePlan: TrailPlan?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroHeader
                trailPlanComposer
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
        .navigationDestination(item: $activePlan) { plan in
            TrailPlanDetailView(plan: plan)
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

    private var trailPlanComposer: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "figure.walk.circle")
                    .foregroundStyle(BiomeTheme.soil)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Build a micro-safari trail plan")
                        .font(.headline)
                    Text("Pick three tiny habitats for this walk. No GPS, no route tracking, just a local field plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Picker("Time budget", selection: $trailPlanMinutes) {
                Text("10 min").tag(10)
                Text("15 min").tag(15)
                Text("20 min").tag(20)
            }
            .pickerStyle(.segmented)
            Button("Build a \(trailPlanMinutes)-minute micro-safari") {
                activePlan = model.createTrailPlan(minutes: trailPlanMinutes)
            }
            .buttonStyle(.borderedProminent)
            .tint(BiomeTheme.soil)
            .accessibilityIdentifier("create-trail-plan-button")
            if let latestPlan = model.trailPlans.first {
                NavigationLink {
                    TrailPlanDetailView(plan: latestPlan)
                } label: {
                    Label("Continue \(latestPlan.title)", systemImage: "arrow.right.circle")
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(BiomeTheme.soil.opacity(0.22)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Micro-Safari Trail Plan composer. Free quests stay open and no GPS is used.")
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

struct TrailPlanDetailView: View {
    @Environment(BiomeAppModel.self) private var model
    let plan: TrailPlan

    private var currentPlan: TrailPlan {
        model.currentTrailPlan(matching: plan)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(currentPlan.title)
                        .font(.title2.bold())
                    Text("Pick three tiny habitats for this walk. Describe clues, not species. Free quests stay open and this plan stays on device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Label("\(currentPlan.estimatedMinutes) minutes", systemImage: "clock")
                        Label("\(currentPlan.completedQuestIds.count) of \(currentPlan.questIds.count) stops", systemImage: "checkmark.circle")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BiomeTheme.soil)
                }
            } header: {
                Text("Micro-Safari Trail Plan")
            }

            Section("Next tiny stops") {
                ForEach(Array(model.quests(for: currentPlan).enumerated()), id: \.element.id) { index, quest in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            HabitatGlyph(habitat: quest.habitatTag)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stop \(index + 1): \(quest.title)")
                                    .font(.headline)
                                Text(nextTinyStop(for: quest))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if currentPlan.containsCompletedQuest(quest.id) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(quest.habitatTag.color)
                            }
                        }
                        HStack {
                            NavigationLink("Capture postcard") {
                                ObservationCaptureView(quest: quest)
                            }
                            Button(currentPlan.containsCompletedQuest(quest.id) ? "Noticed" : "Mark noticed") {
                                model.completeQuest(quest, in: currentPlan)
                            }
                            .disabled(currentPlan.containsCompletedQuest(quest.id))
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 6)
                    .accessibilityLabel("Stop \(index + 1), \(quest.title), \(quest.habitatTag.title)")
                }
            }
        }
        .navigationTitle("Trail Plan")
    }

    private func nextTinyStop(for quest: QuestCard) -> String {
        switch quest.habitatTag {
        case .moss: "Next tiny stop: a shaded wall, curb, or tree base."
        case .bark: "Next tiny stop: one tree trunk with ridges and warm shadows."
        case .pollinator: "Next tiny stop: a flower patch where small wings might pause."
        case .puddle: "Next tiny stop: a wet edge with reflection, grit, or leaf shapes."
        case .stone: "Next tiny stop: stone, brick, or railing with tiny pale circles."
        case .weed: "Next tiny stop: a sidewalk crack with a brave green stem."
        }
    }
}
