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
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DSBTheme.emerald.opacity(0.06))
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
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
                let isSelected = form.frequency == freq
                Button {
                    form.frequency = freq
                } label: {
                    Text(freq.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.2, green: 0.7, blue: 0.45),
                                                    Color(red: 0.15, green: 0.55, blue: 0.35)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.5), .white.opacity(0.1), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(white: 0.94),
                                                    Color(white: 0.82)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.6), .clear],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.white.opacity(0.4) : Color.primary.opacity(0.12), lineWidth: isSelected ? 1 : 1)
                        )
                }
                .buttonStyle(.plain)
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
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12)
                    .fill(DSBTheme.emerald.opacity(0.06))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
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
