//
//  MockHomeData.swift
//  ios
//

import Foundation

enum MockHomeData {
    struct StreakData {
        let label: String
        let days: Int
        let colorName: String
    }

    static let streaks: [StreakData] = [
        StreakData(label: String(localized: "home.streak.relapseFree"), days: 14, colorName: "success"),
        StreakData(label: String(localized: "home.streak.pornFree"), days: 21, colorName: "primary"),
        StreakData(label: String(localized: "home.streak.cleanDays"), days: 7, colorName: "tint"),
        StreakData(label: String(localized: "home.streak.slipUpFree"), days: 30, colorName: "secondary"),
    ]

    static let notificationCount = 3
    static let warningCount = 0

    static var calendarDates: [Date] {
        let calendar = Calendar.current
        let now = Date()
        return (-7...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: now)
        }
    }
}
