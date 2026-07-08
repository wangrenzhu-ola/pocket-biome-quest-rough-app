import SwiftUI

struct PostcardDetailView: View {
    @Environment(BiomeAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var postcard: FieldPostcard
    @State private var showDeleteConfirm = false

    init(postcard: FieldPostcard) {
        _postcard = State(initialValue: postcard)
    }

    var body: some View {
        Form {
            Section("Postcard") {
                HStack {
                    HabitatGlyph(habitat: postcard.habitatTag)
                    VStack(alignment: .leading) {
                        Text(postcard.questTitle).font(.headline)
                        Text(postcard.habitatTag.title).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Edit place clue") {
                TextField("Place clue", text: $postcard.placeClue, axis: .vertical)
            }
            Section("Edit discovery sentence") {
                TextField("Discovery sentence", text: $postcard.discoverySentence, axis: .vertical)
            }
            Section("Texture tags") {
                TextField("Comma-separated textures", text: Binding(
                    get: { postcard.textureTags.joined(separator: ", ") },
                    set: { postcard.textureTags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
            }
            Section("Color tags") {
                TextField("Comma-separated colors", text: Binding(
                    get: { postcard.colorTags.joined(separator: ", ") },
                    set: { postcard.colorTags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
            }
            Section {
                Button("Update postcard") { model.updatePostcard(postcard); dismiss() }
                Button("Delete this field postcard?", role: .destructive) { showDeleteConfirm = true }
            }
        }
        .navigationTitle("Postcard Detail")
        .confirmationDialog("Delete this field postcard?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete \(postcard.questTitle)", role: .destructive) {
                model.deletePostcard(postcard)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the \(postcard.habitatTag.title) postcard from your local trail only.")
        }
    }
}
