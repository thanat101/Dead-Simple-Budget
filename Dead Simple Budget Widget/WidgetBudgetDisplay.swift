//
//  WidgetBudgetDisplay.swift
//  Dead Simple Budget Widget
//
//  Recomputes safe daily and remaining using the same math as BudgetStore, using Date() at
//  timeline load so the widget stays correct across days without opening the app.
//

import Foundation

enum WidgetBudgetDisplay {
    /// Matches BudgetStore.safeDailySpend and remainingThisMonth for a given "now".
    static func compute(fromMonthlySpendable monthlySpendable: Double, now: Date = Date()) -> (safeDaily: Double, remaining: Double) {
        let cal = Calendar.current
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        guard daysInMonth > 0 else { return (0, monthlySpendable) }
        let safeDaily = monthlySpendable / Double(daysInMonth)
        let dayOfMonth = cal.component(.day, from: now)
        let remaining = monthlySpendable - (Double(dayOfMonth) * safeDaily)
        return (safeDaily, remaining)
    }

    /// Mirrors CurrencyHelper.format for the widget target (no SwiftUI dependency).
    static func formatCurrency(_ value: Double, localeIdentifier: String, fractionDigits: Int = 0) -> String {
        let id = localeIdentifier.isEmpty ? "en_US" : localeIdentifier
        let locale = Locale(identifier: id)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        let code = locale.currency?.identifier ?? ""
        if code == "CAD" {
            formatter.currencySymbol = "CA$"
        } else if code == "MXN" {
            formatter.currencySymbol = "MX$"
        }
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func nextStartOfDay(after date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
    }
}
