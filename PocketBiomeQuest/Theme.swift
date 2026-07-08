import SwiftUI

struct BiomeTheme {
    static let paper = Color(red: 0.96, green: 0.92, blue: 0.84)
    static let ink = Color(red: 0.18, green: 0.18, blue: 0.13)
    static let sage = Color(red: 0.63, green: 0.70, blue: 0.55)
    static let lichen = Color(red: 0.82, green: 0.76, blue: 0.39)
    static let soil = Color(red: 0.42, green: 0.31, blue: 0.22)

    static var habitatGradient: LinearGradient {
        LinearGradient(colors: [sage.opacity(0.95), lichen.opacity(0.72), Color(red: 0.61, green: 0.78, blue: 0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct ChipView: View {
    let title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? BiomeTheme.soil.opacity(0.18) : Color.white.opacity(0.72))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? BiomeTheme.soil : BiomeTheme.sage.opacity(0.45)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) chip")
    }
}

struct HabitatGlyph: View {
    let habitat: HabitatTag

    var body: some View {
        ZStack {
            Circle().fill(habitat.color.opacity(0.18))
            Image(systemName: habitat.glyph)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(habitat.color)
        }
        .frame(width: 54, height: 54)
        .accessibilityLabel("\(habitat.title) habitat glyph")
    }
}
