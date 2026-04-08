//
//  PremiumManager.swift
//  Dead Simple Budget
//
//  StoreKit 2: one-time (lifetime) + subscription. Either unlocks Optional adjustments.
//

import SwiftUI
import StoreKit
import Combine

/// Product IDs — must match App Store Connect exactly.
private enum ProductIDs {
    static let lifetime = "com.deadsimplebudget.premium_lifetime"
    static let subscription = "com.deadsimplebudget.premium_monthly"
    static var all: Set<String> { [lifetime, subscription] }
}

@MainActor
final class PremiumManager: ObservableObject {
    @Published private(set) var isPremium = false
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var subscriptionProduct: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task { await listenForTransactions() }
        Task { await refresh() }
    }

    deinit {
        updateTask?.cancel()
    }

    /// Load products and current entitlements.
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var productsError: Error?
        do {
            let products = try await Product.products(for: ProductIDs.all)
            lifetimeProduct = products.first { $0.id == ProductIDs.lifetime }
            subscriptionProduct = products.first { $0.id == ProductIDs.subscription }

            // On real device, if products came back empty, try sync + retry once (helps TestFlight/sandbox propagation).
            #if !targetEnvironment(simulator)
            if lifetimeProduct == nil && subscriptionProduct == nil {
                try? await AppStore.sync()
                let retryProducts = try await Product.products(for: ProductIDs.all)
                lifetimeProduct = retryProducts.first { $0.id == ProductIDs.lifetime }
                subscriptionProduct = retryProducts.first { $0.id == ProductIDs.subscription }
            }
            #endif
        } catch {
            productsError = error
        }

        // Always evaluate entitlements, even if product fetch failed.
        let hasEntitlement = await hasAnyPremiumEntitlement()
        isPremium = hasEntitlement

        // Avoid showing product-fetch errors to users who are already entitled.
        if let productsError, !hasEntitlement {
            errorMessage = productsError.localizedDescription
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                let purchasedID = transaction.productID
                await transaction.finish()
                if ProductIDs.all.contains(purchasedID) {
                    isPremium = true
                }
                await refresh()
                // Simulator / sandbox often lag before currentEntitlements lists the new purchase;
                // we already have a verified transaction for our product.
                if !isPremium, ProductIDs.all.contains(purchasedID) {
                    isPremium = true
                }
                return true
            case .userCancelled:
                return false
            case .pending:
                errorMessage = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                guard ProductIDs.all.contains(transaction.productID) else { continue }
                await transaction.finish()
                await refresh()
                if !isPremium {
                    isPremium = true
                }
            case .unverified:
                continue
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func hasAnyPremiumEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               ProductIDs.all.contains(transaction.productID) {
                return true
            }
        }
        return false
    }
}
