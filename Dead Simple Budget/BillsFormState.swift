//
//  BillsFormState.swift
//  Dead Simple Budget
//
//  Draft state for My Bills sheet. Only syncs to store on appear and on Save.
//

import SwiftUI
import Combine

final class BillsFormState: ObservableObject {
    @Published var lumpSum: Double
    @Published var itemizedBills: [BillItem]

    init(lumpSum: Double = 0, itemizedBills: [BillItem] = []) {
        self.lumpSum = lumpSum
        self.itemizedBills = itemizedBills
    }

    var itemizedIsEmpty: Bool { itemizedBills.isEmpty }

    var totalBills: Double {
        if itemizedBills.isEmpty { return lumpSum }
        return itemizedBills.reduce(0) { $0 + $1.monthlyAmount }
    }

    func syncFrom(_ store: BudgetStore) {
        lumpSum = store.lumpSumBills
        itemizedBills = store.itemizedBills.map { BillItem(id: $0.id, name: $0.name, amount: $0.amount, frequency: $0.frequency) }
    }

    func applyTo(_ store: BudgetStore) {
        store.lumpSumBills = lumpSum
        store.itemizedBills = itemizedBills.map { BillItem(id: $0.id, name: $0.name, amount: $0.amount, frequency: $0.frequency) }
        store.save()
    }

    func binding(for bill: BillItem) -> Binding<BillItem> {
        let id = bill.id
        return Binding(
            get: {
                guard let i = self.itemizedBills.firstIndex(where: { $0.id == id }) else { return bill }
                return self.itemizedBills[i]
            },
            set: { newValue in
                guard let i = self.itemizedBills.firstIndex(where: { $0.id == id }) else { return }
                self.itemizedBills[i] = newValue
            }
        )
    }

    func addDefaultList() {
        for name in BudgetStore.defaultBillNames {
            itemizedBills.append(BillItem(name: name, amount: 0, frequency: .monthly))
        }
    }

    func appendBill() {
        itemizedBills.append(BillItem(name: "", amount: 0, frequency: .monthly))
    }

    func remove(at offsets: IndexSet) {
        itemizedBills.remove(atOffsets: offsets)
    }

    func switchToLumpSum() {
        lumpSum = totalBills
        itemizedBills = []
    }
}
