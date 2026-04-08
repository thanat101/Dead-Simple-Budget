//
//  WidgetSharedData.swift
//  Dead Simple Budget
//
//  Writes budget snapshot to App Group for the widget. Widget reads from same suite.
//

import Foundation
import WidgetKit

enum WidgetSharedData {
    static let appGroupId = "group.Pfeifer.Dead-Simple-Budget"

    private static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    enum Keys {
        static let safeDailyFormatted = "dsb.widget.safeDailyFormatted"
        static let remainingFormatted = "dsb.widget.remainingFormatted"
        static let isPremium = "dsb.widget.isPremium"
        /// Persisted so the widget can recompute daily/remaining with current calendar date without opening the app.
        static let monthlySpendable = "dsb.widget.monthlySpendable"
        static let currencyLocaleIdentifier = "dsb.widget.currencyLocaleIdentifier"
    }

    /// Call from the app whenever budget or premium state changes. Writes monthly spendable + locale for widget-side recomputation; formatted strings kept for legacy fallback.
    static func update(
        monthlySpendable: Double,
        formattedSafeDaily: String,
        formattedRemaining: String,
        currencyLocaleIdentifier: String,
        isPremium: Bool
    ) {
        guard let suite = suite else { return }
        suite.set(monthlySpendable, forKey: Keys.monthlySpendable)
        suite.set(currencyLocaleIdentifier, forKey: Keys.currencyLocaleIdentifier)
        suite.set(formattedSafeDaily, forKey: Keys.safeDailyFormatted)
        suite.set(formattedRemaining, forKey: Keys.remainingFormatted)
        suite.set(isPremium, forKey: Keys.isPremium)
        suite.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
