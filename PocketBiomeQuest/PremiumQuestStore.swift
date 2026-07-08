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

    func purchase(productId: String) async -> PremiumPackState {
        do {
            guard let product = try await Product.products(for: [productId]).first else {
                return unavailablePack(
                    productId: productId,
                    restoreState: "Product unavailable. Free quests still work."
                )
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return PremiumPackState(
                        productId: product.id,
                        displayName: product.displayName,
                        entitlementState: .locked,
                        storeKitAvailability: "Purchase could not be verified.",
                        restoreState: "Try again or use Restore purchase."
                    )
                }
                await transaction.finish()
                return PremiumPackState(
                    productId: product.id,
                    displayName: product.displayName,
                    entitlementState: .purchased,
                    storeKitAvailability: "Purchased on this device.",
                    restoreState: "Purchase restored"
                )
            case .pending:
                return PremiumPackState(
                    productId: product.id,
                    displayName: product.displayName,
                    entitlementState: .locked,
                    storeKitAvailability: "Purchase pending approval.",
                    restoreState: "Restore purchase"
                )
            case .userCancelled:
                return PremiumPackState(
                    productId: product.id,
                    displayName: product.displayName,
                    entitlementState: .locked,
                    storeKitAvailability: "Purchase canceled. Free quests still work.",
                    restoreState: "Restore purchase"
                )
            @unknown default:
                return PremiumPackState(
                    productId: product.id,
                    displayName: product.displayName,
                    entitlementState: .locked,
                    storeKitAvailability: "Purchase unavailable. Free quests still work.",
                    restoreState: "Restore purchase"
                )
            }
        } catch {
            return unavailablePack(productId: productId, restoreState: "Purchase unavailable. Free quests still work.")
        }
    }

    func restorePurchases(currentPacks: [PremiumPackState]) async -> [PremiumPackState] {
        do {
            try await AppStore.sync()
            var purchasedProductIds: Set<String> = []
            for await entitlement in Transaction.currentEntitlements {
                if case .verified(let transaction) = entitlement {
                    purchasedProductIds.insert(transaction.productID)
                }
            }

            return currentPacks.map { pack in
                if purchasedProductIds.contains(pack.productId) {
                    return PremiumPackState(
                        productId: pack.productId,
                        displayName: pack.displayName,
                        entitlementState: .purchased,
                        storeKitAvailability: "Restored on this device.",
                        restoreState: "Purchase restored"
                    )
                }
                return PremiumPackState(
                    productId: pack.productId,
                    displayName: pack.displayName,
                    entitlementState: pack.entitlementState == .unavailable ? .unavailable : .locked,
                    storeKitAvailability: pack.storeKitAvailability,
                    restoreState: "No previous purchase found."
                )
            }
        } catch {
            return currentPacks.map { pack in
                PremiumPackState(
                    productId: pack.productId,
                    displayName: pack.displayName,
                    entitlementState: .unavailable,
                    storeKitAvailability: "StoreKit unavailable. Free quests still work.",
                    restoreState: "Restore unavailable"
                )
            }
        }
    }

    private func unavailablePack(productId: String, restoreState: String) -> PremiumPackState {
        let displayName = Self.defaultPacks.first { $0.productId == productId }?.displayName ?? "Premium Quest Pack"
        return PremiumPackState(
            productId: productId,
            displayName: displayName,
            entitlementState: .unavailable,
            storeKitAvailability: "StoreKit unavailable. Free quests still work.",
            restoreState: restoreState
        )
    }
}
