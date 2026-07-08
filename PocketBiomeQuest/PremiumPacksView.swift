import SwiftUI

struct PremiumPacksView: View {
    @Environment(BiomeAppModel.self) private var model

    var body: some View {
        List {
            Section {
                Text("Premium seasonal quest packs add more micro-biome prompts. The free Quest Deck remains usable without purchase.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Refresh StoreKit products") {
                    Task { await model.refreshPremiumPacks() }
                }
                Button("Restore purchase") {
                    Task { await model.restorePremiumPacks() }
                }
            } header: {
                Text("Premium Quest Packs")
            }
            Section("Seasonal preview") {
                ForEach(model.premiumPacks) { pack in
                    SeasonalPackPreviewCard(pack: pack, preview: SeasonalPackPreview.preview(for: pack.productId))
                }
            }
            Section("Seasonal packs") {
                ForEach(model.premiumPacks) { pack in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(BiomeTheme.lichen)
                            Text(pack.displayName).font(.headline)
                            Spacer()
                            Text(pack.entitlementState.rawValue.capitalized)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.12), in: Capsule())
                        }
                        Text(pack.storeKitAvailability)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Purchase") {
                                Task { await model.purchasePremiumPack(pack) }
                            }
                                .disabled(pack.entitlementState == .unavailable)
                            Button("Restore purchase") {
                                Task { await model.restorePremiumPacks() }
                            }
                        }
                        Text(pack.entitlementState == .unavailable ? "StoreKit unavailable. Free quests still work." : pack.restoreState)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Premium pack \(pack.displayName). \(pack.storeKitAvailability)")
                }
            }
        }
        .navigationTitle("Premium Quest Packs")
    }
}

struct SeasonalPackPreview: Equatable {
    var title: String
    var sampleChain: [String]
    var palette: [String]
    var glyph: String
    var caption: String

    static func preview(for productId: String) -> SeasonalPackPreview {
        switch productId {
        case "pocketbiome.spring.pollinators":
            SeasonalPackPreview(
                title: "Spring Pollinator Field Pack",
                sampleChain: ["Pause for petal motion", "Trace a pollen shadow", "Listen for one wing buzz"],
                palette: ["pollen gold", "petal pink", "leaf green"],
                glyph: "ladybug.fill",
                caption: "Preview this seasonal field pack before purchase. Free quests stay open."
            )
        default:
            SeasonalPackPreview(
                title: "Winter Lichen Field Pack",
                sampleChain: ["Look for pale stone circles", "Compare two cold greens", "Save a frost-edge postcard"],
                palette: ["lichen green", "stone gray", "warm paper"],
                glyph: "circle.hexagongrid.fill",
                caption: "Preview this seasonal field pack before purchase. Free quests stay open."
            )
        }
    }
}

struct SeasonalPackPreviewCard: View {
    let pack: PremiumPackState
    let preview: SeasonalPackPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(BiomeTheme.paper)
                    Image(systemName: preview.glyph)
                        .font(.title.bold())
                        .foregroundStyle(BiomeTheme.soil)
                }
                .frame(width: 62, height: 62)
                VStack(alignment: .leading, spacing: 4) {
                    Text(preview.title)
                        .font(.headline)
                    Text(preview.caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Sample quest chain")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                ForEach(Array(preview.sampleChain.enumerated()), id: \.offset) { index, item in
                    Label("Stop \(index + 1): \(item)", systemImage: pack.entitlementState == .purchased ? "checkmark.circle" : "lock.circle")
                        .font(.subheadline)
                }
            }
            FlowWrap(items: preview.palette) { swatch in
                Text(swatch)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(BiomeTheme.paper, in: Capsule())
            }
            Text("No live recommendations, community feed, species identification, or cloud AI are included.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Seasonal preview for \(preview.title). Free quests stay open.")
    }
}
