//
//  BillsEditView.swift
//  Dead Simple Budget
//
//  My Bills sheet: uses draft state only; store updates on Save. ScrollView (no Form) to avoid gesture conflicts.
//

import SwiftUI

struct BillsEditView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var form: BillsFormState
    let defaultBillsAmount: Double
    let onUseDefault: () -> Void
    let onSave: () -> Void

    @State private var lumpSumText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if form.itemizedIsEmpty {
                    lumpSumSection
                }
                useDefaultSection
                itemizedSection
            }
            .padding(10)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            lumpSumText = form.lumpSum > 0 ? String(Int(form.lumpSum)) : ""
        }
    }

    private var lumpSumSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Monthly bills")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            TextField("0", text: $lumpSumText)
                .font(.footnote)
                .keyboardType(.decimalPad)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background { AdaptiveMetalCard(cornerRadius: 8).clipShape(RoundedRectangle(cornerRadius: 8)) }
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
                .onChange(of: lumpSumText) { _, new in
                    if let v = Double(new.filter { $0.isNumber || $0 == "." }) { form.lumpSum = v }
                }
        }
    }

    private var useDefaultSection: some View {
        Button {
            onUseDefault()
        } label: {
            HStack {
                Text("Use default estimate")
                    .font(.caption2)
                    .fontWeight(.medium)
                Spacer()
                Text(CurrencyHelper.format(defaultBillsAmount))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background { AdaptiveMetalButton(selected: true, cornerRadius: 8).clipShape(RoundedRectangle(cornerRadius: 8)) }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSBTheme.metalStroke(isSelected: true, colorScheme: colorScheme), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }

    private var itemizedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if form.itemizedIsEmpty {
                Button {
                    form.addDefaultList()
                } label: {
                    Label("Start with common bills", systemImage: "list.bullet.rectangle.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background { AdaptiveMetalButton(selected: true, cornerRadius: 8).clipShape(RoundedRectangle(cornerRadius: 8)) }
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSBTheme.metalStroke(isSelected: true, colorScheme: colorScheme), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }

            ForEach(Array(form.itemizedBills.enumerated()), id: \.element.id) { index, bill in
                HStack(alignment: .top, spacing: 6) {
                    BillRowView(bill: form.binding(for: bill))
                        .frame(maxWidth: .infinity)
                    Button(role: .destructive) { form.remove(at: IndexSet(integer: index)) } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .padding(.top, 6)
                }
            }

            Button {
                form.appendBill()
            } label: {
                Label("Add a bill", systemImage: "plus.circle.fill")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background { AdaptiveMetalButton(selected: true, cornerRadius: 8).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSBTheme.metalStroke(isSelected: true, colorScheme: colorScheme), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)

            if !form.itemizedIsEmpty {
                HStack {
                    Text("Total")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Spacer()
                    Text(CurrencyHelper.format(form.totalBills))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background { AdaptiveMetalCard(cornerRadius: 8).clipShape(RoundedRectangle(cornerRadius: 8)) }
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))

                Button("Switch to lump sum", role: .destructive) {
                    form.switchToLumpSum()
                    lumpSumText = form.lumpSum > 0 ? String(Int(form.lumpSum)) : ""
                }
                .font(.caption2)
            }
        }
    }
}

struct BillRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var bill: BillItem
    @State private var amountText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Bill name", text: $bill.name)
                .font(.caption2)
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background { AdaptiveMetalField(cornerRadius: 6).clipShape(RoundedRectangle(cornerRadius: 6)) }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
            HStack(spacing: 4) {
                TextField("Amount", text: $amountText)
                    .font(.caption2)
                    .keyboardType(.decimalPad)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 6)
                    .background { AdaptiveMetalField(cornerRadius: 6).clipShape(RoundedRectangle(cornerRadius: 6)) }
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
                frequencyMenu
            }
        }
        .padding(6)
        .background { AdaptiveMetalCard(cornerRadius: 8).clipShape(RoundedRectangle(cornerRadius: 8)) }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
        .onAppear { amountText = bill.amount > 0 ? String(Int(bill.amount)) : "" }
        .onChange(of: bill.amount) { _, new in
            let s = new > 0 ? String(Int(new)) : ""
            if amountText != s { amountText = s }
        }
        .onChange(of: amountText) { _, new in
            bill.amount = Double(new.filter { $0.isNumber || $0 == "." }) ?? 0
        }
    }

    private var frequencyMenu: some View {
        Menu {
            ForEach(BillFrequency.allCases, id: \.self) { freq in
                Button {
                    bill.frequency = freq
                } label: {
                    Text(freq.rawValue)
                    if bill.frequency == freq { Image(systemName: "checkmark") }
                }
            }
        } label: {
            HStack {
                Text(bill.frequency.rawValue)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .font(.caption2)
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background { AdaptiveMetalField(cornerRadius: 6).clipShape(RoundedRectangle(cornerRadius: 6)) }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
        }
        .tint(DSBTheme.emerald)
    }
}
