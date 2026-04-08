//
//  DeadSimpleBudgetWidget.swift
//  Dead Simple Budget Widget
//
//  Shows Safe Daily Spend and Amount left this month. Premium users only see data; others see upgrade prompt.
//

import WidgetKit
import SwiftUI

// App Group – must match WidgetSharedData in main app
private let appGroupId = "group.Pfeifer.Dead-Simple-Budget"
private enum WidgetKeys {
    static let safeDailyFormatted = "dsb.widget.safeDailyFormatted"
    static let remainingFormatted = "dsb.widget.remainingFormatted"
    static let isPremium = "dsb.widget.isPremium"
    static let monthlySpendable = "dsb.widget.monthlySpendable"
    static let currencyLocaleIdentifier = "dsb.widget.currencyLocaleIdentifier"
}

// Match app theme (widget has no access to DSBTheme)
private let emerald = Color(red: 80/255, green: 200/255, blue: 120/255)

struct BudgetEntry: TimelineEntry {
    let date: Date
    let safeDailyFormatted: String
    let remainingFormatted: String
    let isPremium: Bool
}

struct Provider: TimelineProvider {
    /// Number of future days to prebuild so date rollovers don't depend on an exact midnight refresh callback.
    private let prebuiltDays = 35

    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(), safeDailyFormatted: "$120", remainingFormatted: "$2,400", isPremium: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        let entry = loadEntry(at: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let now = Date()
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)

        var entries: [BudgetEntry] = []
        entries.append(loadEntry(at: now))

        // Prebuild entries for upcoming midnights so the widget can roll over daily without app-open.
        for offset in 1..<prebuiltDays {
            guard let dayStart = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            entries.append(loadEntry(at: dayStart))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func loadEntry(at date: Date) -> BudgetEntry {
        let suite = UserDefaults(suiteName: appGroupId)
        let isPremium = suite?.bool(forKey: WidgetKeys.isPremium) ?? false

        if suite?.object(forKey: WidgetKeys.monthlySpendable) != nil {
            let monthly = suite?.double(forKey: WidgetKeys.monthlySpendable) ?? 0
            let localeId = suite?.string(forKey: WidgetKeys.currencyLocaleIdentifier) ?? ""
            let computed = WidgetBudgetDisplay.compute(fromMonthlySpendable: monthly, now: date)
            let daily = computed.safeDaily.isFinite ? computed.safeDaily : 0
            let rem = computed.remaining.isFinite ? computed.remaining : 0
            return BudgetEntry(
                date: date,
                safeDailyFormatted: WidgetBudgetDisplay.formatCurrency(daily, localeIdentifier: localeId),
                remainingFormatted: WidgetBudgetDisplay.formatCurrency(rem, localeIdentifier: localeId),
                isPremium: isPremium
            )
        }

        let safeDaily = suite?.string(forKey: WidgetKeys.safeDailyFormatted) ?? "—"
        let remaining = suite?.string(forKey: WidgetKeys.remainingFormatted) ?? "—"
        return BudgetEntry(date: date, safeDailyFormatted: safeDaily, remainingFormatted: remaining, isPremium: isPremium)
    }
}

struct DSBWidgetEntryView: View {
    var entry: BudgetEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if entry.isPremium {
            premiumContent
        } else {
            lockContent
        }
    }

    @ViewBuilder
    private var premiumContent: some View {
        let isSmall = family == .systemSmall
        let isMedium = family == .systemMedium

        if isSmall {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(entry.safeDailyFormatted)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(emerald)
                Text("Left")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(entry.remainingFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(10)
            .containerBackground(for: .widget) {
                widgetBackground
            }
        } else if isMedium {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Safe Daily Spend")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(entry.safeDailyFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(emerald)
                    Text("Left this month")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(entry.remainingFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image("WidgetIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
            .containerBackground(for: .widget) {
                widgetBackground
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Safe Daily Spend")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(entry.safeDailyFormatted)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(emerald)
                Text("Left this month")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(entry.remainingFormatted)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(16)
            .containerBackground(for: .widget) {
                widgetBackground
            }
        }
    }

    private var lockContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Upgrade to see your budget")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }

    private var widgetBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.22), Color(white: 0.16)]
                        : [Color(white: 0.96), Color(white: 0.88)],
                    startPoint: .top, endPoint: .bottom
                ))
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [.white.opacity(0.08), .clear]
                        : [.white.opacity(0.5), .clear],
                    startPoint: .top, endPoint: .center
                ))
        }
    }
}

@main
struct DeadSimpleBudgetWidget: Widget {
    let kind: String = "DeadSimpleBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DSBWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget")
        .description("Safe daily spend and amount left this month.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    DeadSimpleBudgetWidget()
} timeline: {
    BudgetEntry(date: .now, safeDailyFormatted: "$120", remainingFormatted: "$2,400", isPremium: true)
}
