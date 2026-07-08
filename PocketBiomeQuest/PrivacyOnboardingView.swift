import SwiftUI

struct PrivacyOnboardingView: View {
    @Environment(BiomeAppModel.self) private var model
    @State private var diagnosticsOptIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Privacy Locale Lock")
                        .font(.largeTitle.bold())
                    Text("Pocket Biome Quest is English (United States) and local-first for version 0.0.1.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                privacyCard(icon: "lock.doc", title: "Local-only trail", body: "Field Postcards, drafts, habitat tags, and photo references stay on this device unless you choose to export text manually.")
                privacyCard(icon: "photo", title: "Optional photo access", body: "Photo access is only used for a local placeholder reference. If permission is unavailable, your words and chips still complete the postcard.")
                privacyCard(icon: "sparkles", title: "No species certainty", body: "Local cue suggestions are simple editable hints, not identification results, online recommendations, or community posts.")
                Toggle("Share optional diagnostics", isOn: $diagnosticsOptIn)
                    .toggleStyle(.switch)
                Button(model.privacy.localOnlyAcknowledged ? "Privacy acknowledged" : "I understand local-only storage") {
                    model.acknowledgePrivacy(localOnly: true, diagnosticsOptIn: diagnosticsOptIn)
                }
                .buttonStyle(.borderedProminent)
                .tint(BiomeTheme.soil)
                Text("Current photo access status: \(model.privacy.photoAccessStatus.replacingOccurrences(of: "_", with: " "))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(BiomeTheme.paper.opacity(0.45))
        .navigationTitle("Privacy")
    }

    private func privacyCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(BiomeTheme.soil)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 20))
    }
}
