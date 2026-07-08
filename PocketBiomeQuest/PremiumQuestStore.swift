import Foundation
import StoreKit

@MainActor
final class PremiumQuestStore {
    static let productIds = ["pocketbiome.seasonal.lichen", "pocketbiome.spring.pollinators"]
    static let defaultPacks = [
        PremiumPackState(productId: "pocketbiome.seasonal.lichen", displayName: "Winter Lichen Pack", entitlementState: .unavailable, storeKitAvailability: "StoreKit products are not loaded on this device.", restoreState: "Nothing restored yet"),
        PremiumPackState(productId: "pocketbiome.spring.pollinators", displayName: "Spring Pollinator Pack", entitlementState: .unavailable, storeKitAvailability: "StoreKit products are not loaded on this device.", restoreState: "Nothing restored yet")
    ]

    func loadProducts() async -> [PremiumPackState] {
        do {
            let products = try await Product.products(for: Self.productIds)
            if products.isEmpty { return Self.defaultPacks }
            return products.map { product in
                PremiumPackState(productId: product.id, displayName: product.displayName, entitlementState: .locked, storeKitAvailability: "Available for purchase", restoreState: "Restore purchase")
            }
        } catch {
            return Self.defaultPacks.map { pack in
                PremiumPackState(productId: pack.productId, displayName: pack.displayName, entitlementState: .unavailable, storeKitAvailability: "StoreKit unavailable. Free quests still work.", restoreState: "Restore unavailable")
            }
        }
    }
}
