//
//  BudgetNotificationManager.swift
//  Dead Simple Budget
//
//  Schedules a weekly local notification for premium users.
//

import Foundation
import UserNotifications

enum BudgetNotificationManager {
    private static let weeklyId = "dsb.weeklyBudgetSummary"

    static func requestAndScheduleWeeklyIfNeeded(
        safeDailySpend: Double,
        remainingThisMonth: Double
    ) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    guard granted else { return }
                    scheduleWeeklyIfNonePending(
                        safeDailySpend: safeDailySpend,
                        remainingThisMonth: remainingThisMonth
                    )
                }
            case .denied:
                // User has turned notifications off for this app.
                return
            case .authorized, .provisional, .ephemeral:
                scheduleWeeklyIfNonePending(
                    safeDailySpend: safeDailySpend,
                    remainingThisMonth: remainingThisMonth
                )
            @unknown default:
                return
            }
        }
    }

    static func cancelWeekly() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [weeklyId])
    }

    // MARK: - Internal helpers

    private static func scheduleWeeklyIfNonePending(
        safeDailySpend: Double,
        remainingThisMonth: Double
    ) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            // If one is already scheduled, keep it (do not reschedule).
            guard !requests.contains(where: { $0.identifier == weeklyId }) else { return }

            let daily = safeDailySpend.isFinite ? safeDailySpend : 0
            let remaining = remainingThisMonth.isFinite ? remainingThisMonth : 0

            let dailyText = CurrencyHelper.format(daily)
            let remainingText = CurrencyHelper.format(remaining)

            let content = UNMutableNotificationContent()
            content.title = "Dead Simple Budget"
            content.body = "Safe Daily Spend: \(dailyText). Left this month: \(remainingText). Remember your daily spending limit is \(dailyText)."
            content.sound = .default

            // Weekly schedule: 7 days from now at 8:00 AM.
            let calendar = Calendar.current
            let now = Date()
            let sevenDaysLater = now.addingTimeInterval(7 * 24 * 60 * 60)

            var components = calendar.dateComponents([.year, .month, .day], from: sevenDaysLater)
            components.hour = 8
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: weeklyId, content: content, trigger: trigger)

            center.add(request, withCompletionHandler: nil)
        }
    }
}

