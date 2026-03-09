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

            var hasEntitlement = false
            for await result in Transaction.currentEntitlements {
                guard let transaction = try? result.payloadValue else { continue }
                if ProductIDs.all.contains(transaction.productID) {
                    hasEntitlement = true
                    break
                }
            }
            isPremium = hasEntitlement
        } catch {
            errorMessage = error.localizedDescription
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
                await transaction.finish()
                await refresh()
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
            guard let transaction = try? result.payloadValue else { continue }
            if ProductIDs.all.contains(transaction.productID) {
                await transaction.finish()
                await refresh()
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
}
