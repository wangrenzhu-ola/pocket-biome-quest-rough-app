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
            } header: {
                Text("Premium Quest Packs")
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
                            Button("Purchase") { }
                                .disabled(pack.entitlementState == .unavailable)
                            Button("Restore purchase") { }
                                .disabled(pack.entitlementState == .unavailable)
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
