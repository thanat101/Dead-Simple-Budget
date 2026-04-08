//
//  OptionalAdjustmentsView.swift
//  Dead Simple Budget
//
//  Optional adjustments section: Take-home pay, Bills, Savings, Currency. Links to main ContentView actions.
//

import SwiftUI

struct OptionalAdjustmentsView: View {
    @Binding var isExpanded: Bool
    let isPremium: Bool
    let monthlyIncome: Double
    let totalBills: Double
    let savingsMonthlyEquivalent: Double
    let savingsEnabled: Binding<Bool>
    let onSaveSavings: () -> Void
    let onEditPaycheck: () -> Void
    let onEditBills: () -> Void
    let onEditSavings: () -> Void
    let onRequestPremium: () -> Void
    @Binding var currencyLocaleId: String

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 12) {
                AdjustmentRowView(
                    title: "Take-home pay",
                    value: monthlyIncome,
                    action: onEditPaycheck
                )
                AdjustmentRowView(
                    title: "Bills",
                    value: totalBills,
                    action: onEditBills
                )
                AdjustmentRowView(
                    title: "Savings",
                    value: savingsMonthlyEquivalent,
                    action: onEditSavings,
                    toggle: savingsEnabled,
                    onToggle: onSaveSavings,
                    isPremium: isPremium
                )
                CurrencyRowView(
                    currencyLocaleId: $currencyLocaleId,
                    isPremium: isPremium,
                    onRequestPremium: onRequestPremium
                )
            }
            .padding(.top, 8)
        } label: {
            Text("More features")
                .font(.system(size: 23))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .tint(DSBTheme.emerald)
    }
}

struct AdjustmentRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: Double
    let action: () -> Void
    var toggle: Binding<Bool>? = nil
    var onToggle: (() -> Void)? = nil
    var isPremium: Bool = true

    var body: some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.primary)
            Spacer()
            if let toggle = toggle {
                if isPremium {
                    Toggle("", isOn: toggle)
                        .labelsHidden()
                        .tint(DSBTheme.emerald)
                        .onChange(of: toggle.wrappedValue) { _, _ in onToggle?() }
                        .frame(width: 51, height: 44, alignment: .center)
                } else {
                    ZStack {
                        Color.clear
                        Image(systemName: "circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 51, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture { action() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Unlock savings")
                }
            } else {
                Color.clear
                    .frame(width: 51, height: 44)
            }
            Text(CurrencyHelper.format(value))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 120, alignment: .trailing)
            EditButton(action: action)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background { AdaptiveMetalCard(cornerRadius: DSBTheme.cornerRadiusRow).clipShape(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusRow)) }
        .overlay(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusRow).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
    }
}

private struct EditButton: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.clear
            Text("Edit")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(DSBTheme.emerald)
        }
        .frame(width: 60, height: 44, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Edit")
    }
}

struct CurrencyRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var currencyLocaleId: String
    var isPremium: Bool = true
    var onRequestPremium: (() -> Void)?

    var body: some View {
        HStack {
            Text("Currency")
                .font(.footnote)
                .foregroundStyle(Color.primary)
            Spacer()
            if isPremium {
                Menu {
                    ForEach(CurrencyHelper.currencyOptions, id: \.localeId) { option in
                        Button {
                            currencyLocaleId = option.localeId
                        } label: {
                            Text(option.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(CurrencyHelper.currencyOptions.first(where: { $0.localeId == currencyLocaleId })?.name ?? "Device")
                            .font(.footnote)
                            .foregroundStyle(DSBTheme.emerald)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                .tint(DSBTheme.emerald)
            } else {
                ZStack {
                    Color.clear
                    HStack {
                        Text(CurrencyHelper.currencyOptions.first(where: { $0.localeId == currencyLocaleId })?.name ?? "Device")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .onTapGesture { onRequestPremium?() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Unlock currency")
            }
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background { AdaptiveMetalCard(cornerRadius: DSBTheme.cornerRadiusRow).clipShape(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusRow)) }
        .overlay(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusRow).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
    }
}
