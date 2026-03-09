//
//  SavingsFormState.swift
//  Dead Simple Budget
//
//  Draft state for Savings sheet. Only syncs to store on appear and on Save.
//

import SwiftUI
import Combine

final class SavingsFormState: ObservableObject {
    @Published var enabled: Bool
    @Published var mode: SavingsMode
    @Published var percent: Double
    @Published var goalAmount: Double
    @Published var goalFrequency: SavingsGoalFrequency

    /// Used only for "about X per month" display (from main store).
    var monthlyIncomeFromStore: Double = 0

    init(
        enabled: Bool = false,
        mode: SavingsMode = .percentOfIncome,
        percent: Double = 10,
        goalAmount: Double = 500,
        goalFrequency: SavingsGoalFrequency = .monthly
    ) {
        self.enabled = enabled
        self.mode = mode
        self.percent = percent
        self.goalAmount = goalAmount
        self.goalFrequency = goalFrequency
    }

    var monthlyEquivalent: Double {
        guard enabled else { return 0 }
        switch mode {
        case .percentOfIncome:
            return monthlyIncomeFromStore * (percent / 100.0)
        case .goalAmount:
            switch goalFrequency {
            case .weekly: return goalAmount * (52.0 / 12.0)
            case .monthly: return goalAmount
            case .yearly: return goalAmount / 12.0
            }
        }
    }

    func syncFrom(_ store: BudgetStore) {
        enabled = store.savingsEnabled
        mode = store.savingsMode
        percent = store.savingsPercent
        goalAmount = store.savingsGoalAmount
        goalFrequency = store.savingsGoalFrequency
        monthlyIncomeFromStore = store.monthlyIncome
    }

    func applyTo(_ store: BudgetStore) {
        store.savingsEnabled = enabled
        store.savingsMode = mode
        store.savingsPercent = percent
        store.savingsGoalAmount = goalAmount
        store.savingsGoalFrequency = goalFrequency
        store.save()
    }
}
