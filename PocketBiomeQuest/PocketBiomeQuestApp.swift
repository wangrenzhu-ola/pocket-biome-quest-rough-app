import SwiftUI

@main
struct PocketBiomeQuestApp: App {
    @State private var model = BiomeAppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
