//
//  CurrencyHelper.swift
//  Dead Simple Budget
//

import Foundation
import SwiftUI

/// Uses the device locale (or a saved preference) for currency symbol and formatting.
enum CurrencyHelper {
    static let currencyOptionKey = "dsb.currencyLocaleIdentifier"

    /// Locale for formatting. Set from saved preference or device locale.
    static var currentLocale: Locale = .current

    /// Apply a saved locale identifier (call on launch and when user changes currency).
    /// Defaults to US Dollar when no preference is saved.
    static func applySavedLocale(identifier: String?) {
        if let id = identifier, !id.isEmpty {
            currentLocale = Locale(identifier: id)
        } else {
            // Hard default to US Dollar so the app and widget start in USD.
            currentLocale = Locale(identifier: "en_US")
        }
    }

    /// Options for the currency picker (alphabetical by name; empty = device default).
    static let currencyOptions: [(name: String, localeId: String)] = [
        ("British Pound (£)", "en_GB"),
        ("Canadian Dollar (CA$)", "en_CA"),
        ("Chinese Yuan (¥)", "zh_CN"),
        ("Device", ""),
        ("Euro (€)", "de_DE"),
        ("Indian Rupee (₹)", "en_IN"),
        ("Mexican Peso (MX$)", "es_MX"),
        ("Russian Ruble (₽)", "ru_RU"),
        ("US Dollar ($)", "en_US")
    ]

    /// Currency symbol for the current locale. Uses distinct symbols for CAD/MXN so they’re not confused with US "$".
    static var currencySymbol: String {
        switch currentLocale.currency?.identifier ?? "" {
        case "CAD": return "CA$"
        case "MXN": return "MX$"
        default: return currentLocale.currencySymbol ?? "$"
        }
    }

    /// Format a value as currency using the current locale.
    static func format(_ value: Double, fractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currentLocale
        let code = currentLocale.currency?.identifier ?? ""
        if code == "CAD" {
            formatter.currencySymbol = "CA$"
        } else if code == "MXN" {
            formatter.currencySymbol = "MX$"
        }
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Format an integer with grouping (e.g. "1,234" or "1.234") for use with a separate currency symbol.
    static func formatIntegerWithGrouping(_ value: Double) -> String {
        let n = Int(value.rounded())
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = currentLocale
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: n)) ?? "0"
    }

    /// Parse a string that may contain grouping separators (e.g. "1,234" or "1.234") into a number.
    static func parseAmountFromString(_ s: String) -> Double? {
        let grouping = currentLocale.groupingSeparator ?? ","
        let decimal = currentLocale.decimalSeparator ?? "."
        var cleaned = s.replacingOccurrences(of: grouping, with: "")
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        let allowed = CharacterSet(charactersIn: "0123456789" + decimal)
        cleaned = cleaned.filter { char in char.unicodeScalars.first.map { allowed.contains($0) } ?? false }
        cleaned = cleaned.replacingOccurrences(of: decimal, with: ".")
        return Double(cleaned)
    }
}
