//
//  IncomeEditView.swift
//  Dead Simple Budget
//
//  Take-home pay sheet: one amount + Weekly/Biweekly/Monthly. Dead simple.
//

import SwiftUI

struct IncomeEditView: View {
    @ObservedObject var form: IncomeFormState
    let onSave: () -> Void

    @State private var amountText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Use the amount that actually hits your bank account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                frequencyButtons

                VStack(alignment: .leading, spacing: 8) {
                    Text("Take-home income")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onChange(of: amountText) { _, new in
                            if let v = Double(new.filter { $0.isNumber || $0 == "." }) { form.amount = v }
                        }
                }

                monthlyEquivalentRow
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            amountText = form.amount > 0 ? (form.amount == floor(form.amount) ? String(Int(form.amount)) : String(format: "%.2g", form.amount)) : ""
        }
        .onChange(of: form.amount) { _, _ in
            amountText = form.amount > 0 ? (form.amount == floor(form.amount) ? String(Int(form.amount)) : String(format: "%.2g", form.amount)) : ""
        }
    }

    private var frequencyButtons: some View {
        HStack(spacing: 10) {
            ForEach(IncomeFrequency.allCases, id: \.self) { freq in
                Button {
                    form.frequency = freq
                } label: {
                    Text(freq.rawValue)
                        .font(.subheadline)
                        .fontWeight(form.frequency == freq ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(form.frequency == freq ? DSBTheme.emerald : .secondary)
            }
        }
    }

    private var monthlyEquivalentRow: some View {
        HStack {
            Text("Monthly equivalent")
                .fontWeight(.medium)
            Spacer()
            Text(CurrencyHelper.format(form.monthlyIncome))
                .foregroundStyle(DSBTheme.emerald)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Simple flow layout for wrapping buttons (used by SavingsEditView).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[i].x, y: bounds.minY + result.positions[i].y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? 400
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
