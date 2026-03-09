//
//  PaywallView.swift
//  Dead Simple Budget
//
//  Unlock Optional adjustments: one-time or subscription.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var manager: PremiumManager
    @Binding var isPresented: Bool

    private var simulatorStoreKitMessage: String {
        #if targetEnvironment(simulator)
        return "In Xcode: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → Configuration.storekit, then run again."
        #else
        return "Products are still loading or need to be set up in App Store Connect. Try again in a moment or update the app later."
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Unlock all features")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Edit take-home pay, bills, savings, and currency to get a more accurate Safe Daily Spend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let msg = manager.errorMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if manager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        let hasProducts = manager.lifetimeProduct != nil || manager.subscriptionProduct != nil
                        if !hasProducts {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Purchase options unavailable")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(simulatorStoreKitMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Retry") {
                                    Task { await manager.refresh() }
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(DSBTheme.emerald)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if let sub = manager.subscriptionProduct {
                            Button {
                                Task {
                                    if await manager.purchase(sub) {
                                        isPresented = false
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Subscribe")
                                            .fontWeight(.semibold)
                                        Text(sub.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(sub.displayPrice)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
                            .disabled(manager.isLoading)
                        }

                        if let lifetime = manager.lifetimeProduct {
                            Button {
                                Task {
                                    if await manager.purchase(lifetime) {
                                        isPresented = false
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Buy once")
                                            .fontWeight(.semibold)
                                        Text("Lifetime access")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(lifetime.displayPrice)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
                            .disabled(manager.isLoading)
                        }
                    }

                    Button("Restore purchases") {
                        Task {
                            await manager.restore()
                            if manager.isPremium {
                                isPresented = false
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(DSBTheme.emerald)
                    .disabled(manager.isLoading)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: manager.isPremium) { _, isPremium in
            if isPremium { isPresented = false }
        }
        .onAppear {
            Task {
                // Refresh when paywall opens if we don't have products yet (second chance for TestFlight).
                if manager.lifetimeProduct == nil && manager.subscriptionProduct == nil {
                    await manager.refresh()
                }
            }
        }
    }
}
