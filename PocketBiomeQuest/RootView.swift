import SwiftUI

struct RootView: View {
    @Environment(BiomeAppModel.self) private var model

    var body: some View {
        TabView(selection: Bindable(model).selectedTab) {
            NavigationStack {
                QuestDeckView()
            }
            .tabItem { Label("Quests", systemImage: "leaf") }
            .tag(BiomeAppModel.AppTab.quests)

            NavigationStack {
                TrailArchiveView()
            }
            .tabItem { Label("Trail", systemImage: "postcard") }
            .tag(BiomeAppModel.AppTab.archive)

            NavigationStack {
                PremiumPacksView()
            }
            .tabItem { Label("Packs", systemImage: "sparkles") }
            .tag(BiomeAppModel.AppTab.premium)

            NavigationStack {
                PrivacyOnboardingView()
            }
            .tabItem { Label("Privacy", systemImage: "hand.raised") }
            .tag(BiomeAppModel.AppTab.privacy)
        }
        .tint(BiomeTheme.soil)
        .overlay(alignment: .top) {
            if let message = model.successMessage {
                Text(message)
                    .font(.callout.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .accessibilityIdentifier("success-toast")
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        model.successMessage = nil
                    }
            }
        }
    }
}
