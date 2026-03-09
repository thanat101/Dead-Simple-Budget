//
//  SavingsEditView.swift
//  Dead Simple Budget
//
//  Savings sheet: uses draft state only; store updates on Save. ScrollView + buttons (no Form).
//

import SwiftUI

struct SavingsEditView: View {
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
                Button("Goal") {
                    form.mode = .goalAmount
                }
                .buttonStyle(.bordered)
                .tint(form.mode == .goalAmount ? DSBTheme.emerald : .secondary)
                Button("Percent of income") {
                    form.mode = .percentOfIncome
                }
                .buttonStyle(.bordered)
                .tint(form.mode == .percentOfIncome ? DSBTheme.emerald : .secondary)
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
                    Button {
                        form.percent = pct
                    } label: {
                        Text("\(Int(pct))%")
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(form.percent == pct ? DSBTheme.emerald : .secondary)
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
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("Per")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(SavingsGoalFrequency.allCases, id: \.self) { freq in
                    Button {
                        form.goalFrequency = freq
                    } label: {
                        Text(freq.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(form.goalFrequency == freq ? DSBTheme.emerald : .secondary)
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
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
