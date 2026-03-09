//
//  IncomeFormState.swift
//  Dead Simple Budget
//
//  Draft state for Take-home pay sheet. Only syncs to store on appear and on Save.
//

import SwiftUI
import Combine

final class IncomeFormState: ObservableObject {
    @Published var frequency: IncomeFrequency
    @Published var amount: Double

    init(frequency: IncomeFrequency = .monthly, amount: Double = 0) {
        self.frequency = frequency
        self.amount = amount
    }

    func syncFrom(_ store: BudgetStore) {
        frequency = store.incomeFrequency
        amount = store.incomeAmount
    }

    func applyTo(_ store: BudgetStore) {
        store.incomeFrequency = frequency
        store.incomeAmount = amount
        store.save()
    }

    var monthlyIncome: Double {
        switch frequency {
        case .monthly: return amount
        case .weekly: return amount * (52.0 / 12.0)
        case .biweekly: return amount * (26.0 / 12.0)
        }
    }
}
