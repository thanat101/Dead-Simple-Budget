//
//  BillsEditView.swift
//  Dead Simple Budget
//
//  My Bills sheet: uses draft state only; store updates on Save. ScrollView (no Form) to avoid gesture conflicts.
//

import SwiftUI

struct BillsEditView: View {
    @ObservedObject var form: BillsFormState
    let defaultBillsAmount: Double
    let onUseDefault: () -> Void
    let onSave: () -> Void

    @State private var lumpSumText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if form.itemizedIsEmpty {
                    lumpSumSection
                }
                useDefaultSection
                itemizedSection
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            lumpSumText = form.lumpSum > 0 ? String(Int(form.lumpSum)) : ""
        }
    }

    private var lumpSumSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly bills")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            TextField("0", text: $lumpSumText)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                Spacer()
                Text(CurrencyHelper.format(defaultBillsAmount))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .foregroundStyle(DSBTheme.emerald)
    }

    private var itemizedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if form.itemizedIsEmpty {
                Button {
                    form.addDefaultList()
                } label: {
                    Label("Start with common bills", systemImage: "list.bullet.rectangle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .foregroundStyle(DSBTheme.emerald)
            }

            ForEach(Array(form.itemizedBills.enumerated()), id: \.element.id) { index, bill in
                HStack(alignment: .top, spacing: 8) {
                    BillRowView(bill: form.binding(for: bill))
                        .frame(maxWidth: .infinity)
                    Button(role: .destructive) { form.remove(at: IndexSet(integer: index)) } label: {
                        Image(systemName: "trash")
                            .font(.body)
                    }
                    .padding(.top, 8)
                }
            }

            Button {
                form.appendBill()
            } label: {
                Label("Add a bill", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(DSBTheme.emerald)

            if !form.itemizedIsEmpty {
                HStack {
                    Text("Total")
                        .fontWeight(.medium)
                    Spacer()
                    Text(CurrencyHelper.format(form.totalBills))
                        .foregroundStyle(.secondary)
                }
                .padding()

                Button("Switch to lump sum", role: .destructive) {
                    form.switchToLumpSum()
                    lumpSumText = form.lumpSum > 0 ? String(Int(form.lumpSum)) : ""
                }
            }
        }
    }
}

struct BillRowView: View {
    @Binding var bill: BillItem
    @State private var amountText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Bill name", text: $bill.name)
                .padding(10)
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 8) {
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                frequencyMenu
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    .font(.caption)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .tint(DSBTheme.emerald)
    }
}
