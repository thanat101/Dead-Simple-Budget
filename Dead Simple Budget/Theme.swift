//
//  Theme.swift
//  Dead Simple Budget
//
//  Central design tokens for a modern, Apple-style look. Adaptive for light/dark mode.
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

    // MARK: - Adaptive metal (light/dark mode)
    /// Stroke color for metal surfaces. Use with overlay.
    static func metalStroke(isSelected: Bool, colorScheme: ColorScheme) -> Color {
        if isSelected { return .white.opacity(0.4) }
        return colorScheme == .dark ? .white.opacity(0.15) : .primary.opacity(0.08)
    }
}

// MARK: - Adaptive metal backgrounds (read colorScheme from environment)

struct AdaptiveMetalCard: View {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = DSBTheme.cornerRadiusCard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.22), Color(white: 0.16)]
                        : [Color(white: 0.94), Color(white: 0.82)],
                    startPoint: .top, endPoint: .bottom
                ))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [.white.opacity(0.08), .clear]
                        : [.white.opacity(0.6), .clear],
                    startPoint: .top, endPoint: .center
                ))
        }
    }
}

struct AdaptiveMetalButton: View {
    @Environment(\.colorScheme) private var colorScheme
    var selected: Bool
    var cornerRadius: CGFloat = DSBTheme.cornerRadiusButton

    var body: some View {
        ZStack {
            if selected {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: [Color(red: 0.2, green: 0.7, blue: 0.45), Color(red: 0.15, green: 0.55, blue: 0.35)], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .center))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(white: 0.22), Color(white: 0.16)]
                            : [Color(white: 0.94), Color(white: 0.82)],
                        startPoint: .top, endPoint: .bottom
                    ))
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(
                        colors: colorScheme == .dark
                            ? [.white.opacity(0.08), .clear]
                            : [.white.opacity(0.6), .clear],
                        startPoint: .top, endPoint: .center
                    ))
            }
        }
    }
}

struct AdaptiveMetalField: View {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.28), Color(white: 0.20)]
                        : [Color(white: 0.96), Color(white: 0.88)],
                    startPoint: .top, endPoint: .bottom
                ))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [.white.opacity(0.06), .clear]
                        : [.white.opacity(0.5), .clear],
                    startPoint: .top, endPoint: .center
                ))
        }
    }
}
