//
//  SavingsEditView.swift
//  Dead Simple Budget
//
//  Savings sheet: uses draft state only; store updates on Save. ScrollView + buttons (no Form).
//

import SwiftUI

struct SavingsEditView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var form: SavingsFormState
    let onSave: () -> Void

    @State private var goalAmountText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Enable savings", isOn: $form.enabled)
                    .tint(DSBTheme.emerald)
                    .padding()

                if form.enabled {
                    modeButtons
                    if form.mode == .percentOfIncome {
                        percentSection
                    } else {
                        goalSection
                    }
                    monthlyRow
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            goalAmountText = form.goalAmount > 0 ? String(Int(form.goalAmount)) : ""
        }
        .onChange(of: goalAmountText) { _, new in
            if let v = Double(new.filter { $0.isNumber || $0 == "." }) { form.goalAmount = v }
        }
    }

    private var modeButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Either")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach([(SavingsMode.goalAmount, "Goal"), (SavingsMode.percentOfIncome, "Percent of income")], id: \.0.rawValue) { mode, label in
                    let isSelected = form.mode == mode
                    Button {
                        form.mode = mode
                    } label: {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background { AdaptiveMetalButton(selected: isSelected, cornerRadius: 12) }
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DSBTheme.metalStroke(isSelected: isSelected, colorScheme: colorScheme), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var percentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Percent of income")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            let percents: [Double] = [2, 5, 10, 15, 20, 25, 30]
            FlowLayout(spacing: 8) {
                ForEach(percents, id: \.self) { pct in
                    let isSelected = form.percent == pct
                    Button {
                        form.percent = pct
                    } label: {
                        Text("\(Int(pct))%")
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background { AdaptiveMetalButton(selected: isSelected, cornerRadius: 10) }
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DSBTheme.metalStroke(isSelected: isSelected, colorScheme: colorScheme), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goal amount")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("0", text: $goalAmountText)
                .keyboardType(.decimalPad)
                .padding(10)
                .background { AdaptiveMetalField(cornerRadius: 12).clipShape(RoundedRectangle(cornerRadius: 12)) }
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
            Text("Per")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(SavingsGoalFrequency.allCases, id: \.self) { freq in
                    let isSelected = form.goalFrequency == freq
                    Button {
                        form.goalFrequency = freq
                    } label: {
                        Text(freq.rawValue)
                            .font(.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background { AdaptiveMetalButton(selected: isSelected, cornerRadius: 10) }
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DSBTheme.metalStroke(isSelected: isSelected, colorScheme: colorScheme), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthlyRow: some View {
        HStack {
            Text("Monthly equivalent")
                .fontWeight(.medium)
            Spacer()
            Text(CurrencyHelper.format(form.monthlyEquivalent))
                .foregroundStyle(DSBTheme.emerald)
        }
        .padding()
        .background { AdaptiveMetalField(cornerRadius: 12).clipShape(RoundedRectangle(cornerRadius: 12)) }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
    }
}
