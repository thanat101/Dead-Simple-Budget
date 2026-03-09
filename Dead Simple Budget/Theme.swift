//
//  Theme.swift
//  Dead Simple Budget
//
//  Central design tokens for a modern, Apple-style look. No functionality changes.
//

import SwiftUI

enum DSBTheme {
    // MARK: - Accent
    /// Primary accent (buttons, highlights, positive amounts).
    static let emerald = Color(red: 80/255, green: 200/255, blue: 120/255)
    /// Softer tint for selected states and backgrounds.
    static let emeraldTint = Color(red: 80/255, green: 200/255, blue: 120/255).opacity(0.18)
    /// Dark-mode friendly accent (slightly brighter).
    static let emeraldAdaptive = Color(red: 52/255, green: 199/255, blue: 89/255)

    // MARK: - Surfaces (system-aligned for light/dark)
    static var cardBackground: Color { Color(UIColor.secondarySystemBackground) }
    static var groupedBackground: Color { Color(UIColor.tertiarySystemFill) }
    static var sheetBackground: Color { Color(UIColor.systemBackground) }

    // MARK: - Corner radius
    static let cornerRadiusCard: CGFloat = 14
    static let cornerRadiusRow: CGFloat = 12
    static let cornerRadiusButton: CGFloat = 12

    // MARK: - Typography (semantic sizes; actual fonts applied in views)
    static let titleLargeSize: CGFloat = 28
    static let headlineSize: CGFloat = 22
    static let bodySize: CGFloat = 17
    static let calloutSize: CGFloat = 16
    static let subheadlineSize: CGFloat = 15
    static let footnoteSize: CGFloat = 13
}
