//
//  BudgetStore.swift
//  Dead Simple Budget
//

import SwiftUI
import Combine

/// How often take-home pay hits the bank.
enum IncomeFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
}

enum SavingsMode: String, Codable, CaseIterable {
    case percentOfIncome = "Percent of income"
    case goalAmount = "Goal"
}

enum SavingsGoalFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

final class BudgetStore: ObservableObject {
    static let defaultBills: Double = 3000

    /// Default itemized bill names for "Start with common bills".
    static let defaultBillNames: [String] = [
        "Mortgage / rent",
        "Auto insurance",
        "Car payment / auto loan",
        "Electricity",
        "Phone (cell/land)",
        "Groceries/Food",
        "Internet",
        "Cable",
        "Water/sewer",
        "Gas / utility",
        "Health insurance"
    ]

    /// Take-home amount per period (what actually hits the bank).
    @Published var incomeFrequency: IncomeFrequency
    @Published var incomeAmount: Double

    /// Monthly income for Safe Daily Spend (from take-home + frequency).
    var monthlyIncome: Double {
        switch incomeFrequency {
        case .monthly: return incomeAmount
        case .weekly: return incomeAmount * (52.0 / 12.0)
        case .biweekly: return incomeAmount * (26.0 / 12.0)
        }
    }

    @Published var lumpSumBills: Double
    @Published var itemizedBills: [BillItem]
    @Published var savingsEnabled: Bool
    @Published var savingsMode: SavingsMode
    @Published var savingsPercent: Double       // e.g. 10 for 10%
    @Published var savingsGoalAmount: Double
    @Published var savingsGoalFrequency: SavingsGoalFrequency

    /// Monthly savings used in Safe Daily Spend (from percent or goal).
    var savingsMonthlyEquivalent: Double {
        guard savingsEnabled else { return 0 }
        switch savingsMode {
        case .percentOfIncome:
            return monthlyIncome * (savingsPercent / 100.0)
        case .goalAmount:
            switch savingsGoalFrequency {
            case .weekly: return savingsGoalAmount * (52.0 / 12.0)
            case .monthly: return savingsGoalAmount
            case .yearly: return savingsGoalAmount / 12.0
            }
        }
    }

    /// Total bills: from itemized list if any, otherwise lump sum.
    var totalBills: Double {
        if itemizedBills.isEmpty {
            return lumpSumBills
        }
        return itemizedBills.reduce(0) { $0 + $1.monthlyAmount }
    }

    /// Total amount available to spend for the whole month after bills and savings.
    var monthlySpendable: Double {
        monthlyIncome - totalBills - savingsMonthlyEquivalent
    }

    /// Estimated amount left to spend this month (budget minus days-passed × daily spend). Assumes you've spent safeDailySpend each day so far.
    var remainingThisMonth: Double {
        let dayOfMonth = Calendar.current.component(.day, from: Date())
        let daysPassed = dayOfMonth
        return monthlySpendable - (Double(daysPassed) * safeDailySpend)
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let incomeFrequency = "dsb.incomeFrequency"
        static let incomeAmount = "dsb.incomeAmount"
        static let lumpSumBills = "dsb.lumpSumBills"
        static let itemizedBills = "dsb.itemizedBills"
        static let savingsEnabled = "dsb.savingsEnabled"
        static let savingsMode = "dsb.savingsMode"
        static let savingsPercent = "dsb.savingsPercent"
        static let savingsGoalAmount = "dsb.savingsGoalAmount"
        static let savingsGoalFrequency = "dsb.savingsGoalFrequency"
    }

    init() {
        let freqRaw = defaults.string(forKey: Keys.incomeFrequency) ?? ""
        self.incomeFrequency = IncomeFrequency(rawValue: freqRaw) ?? .monthly
        let amt = defaults.double(forKey: Keys.incomeAmount)
        self.incomeAmount = amt == 0 ? 4000 : amt
        let lump = defaults.double(forKey: Keys.lumpSumBills)
        let savingsEn = defaults.bool(forKey: Keys.savingsEnabled)
        let modeRaw = defaults.string(forKey: Keys.savingsMode) ?? ""
        self.savingsMode = SavingsMode(rawValue: modeRaw) ?? .percentOfIncome
        let pct = defaults.double(forKey: Keys.savingsPercent)
        self.savingsPercent = pct == 0 ? 10 : pct
        let goalAmt = defaults.double(forKey: Keys.savingsGoalAmount)
        self.savingsGoalAmount = goalAmt == 0 ? 500 : goalAmt
        let savingsFreqRaw = defaults.string(forKey: Keys.savingsGoalFrequency) ?? ""
        self.savingsGoalFrequency = SavingsGoalFrequency(rawValue: savingsFreqRaw) ?? .monthly

        self.lumpSumBills = lump == 0 ? Self.defaultBills : lump
        self.itemizedBills = (try? JSONDecoder().decode([BillItem].self, from: defaults.data(forKey: Keys.itemizedBills) ?? Data())) ?? []
        self.savingsEnabled = savingsEn
    }

    var daysInCurrentMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    /// Set income to a simple monthly amount (e.g. from main-view edit).
    func setMonthlyIncomeFromSimple(_ value: Double) {
        incomeFrequency = .monthly
        incomeAmount = value
    }

    /// Safe Daily Spend = (Income − Bills − Optional Savings) ÷ Days in Month (can be negative)
    var safeDailySpend: Double {
        let net = monthlySpendable
        guard daysInCurrentMonth > 0 else { return 0 }
        return net / Double(daysInCurrentMonth)
    }

    /// Skip bills: use default average and clear itemized list.
    func useDefaultBills() {
        lumpSumBills = Self.defaultBills
        itemizedBills = []
        save()
    }

    func save() {
        defaults.set(incomeFrequency.rawValue, forKey: Keys.incomeFrequency)
        defaults.set(incomeAmount, forKey: Keys.incomeAmount)
        defaults.set(lumpSumBills, forKey: Keys.lumpSumBills)
        if let data = try? JSONEncoder().encode(itemizedBills) {
            defaults.set(data, forKey: Keys.itemizedBills)
        }
        defaults.set(savingsEnabled, forKey: Keys.savingsEnabled)
        defaults.set(savingsMode.rawValue, forKey: Keys.savingsMode)
        defaults.set(savingsPercent, forKey: Keys.savingsPercent)
        defaults.set(savingsGoalAmount, forKey: Keys.savingsGoalAmount)
        defaults.set(savingsGoalFrequency.rawValue, forKey: Keys.savingsGoalFrequency)
    }

}

private extension UserDefaults {
    func contains(key: String) -> Bool {
        object(forKey: key) != nil
    }
}
