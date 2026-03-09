//
//  BillItem.swift
//  Dead Simple Budget
//

import SwiftUI

struct BillItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var amount: Double
    var frequency: BillFrequency

    init(id: UUID = UUID(), name: String = "", amount: Double = 0, frequency: BillFrequency = .monthly) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequency = frequency
    }

    /// Converts this bill to a monthly amount for the budget calculation.
    var monthlyAmount: Double {
        switch frequency {
        case .monthly: return amount
        case .weekly: return amount * (52.0 / 12.0)
        case .biweekly: return amount * (26.0 / 12.0)
        case .semiAnnually: return amount / 6.0
        case .annually: return amount / 12.0
        }
    }
}

enum BillFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case semiAnnually = "Every 6 months"
    case annually = "Annually"
}
