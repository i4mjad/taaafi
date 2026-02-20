//
//  TotalActivityReport.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (ActivityReport) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var totalPickups = 0
        var totalNotifications = 0
        // category name -> (duration, app name -> (duration, pickups, notifications))
        var categoryMap: [String: (duration: TimeInterval, apps: [String: (duration: TimeInterval, pickups: Int, notifications: Int)])] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    let categoryName = categoryActivity.category.localizedDisplayName ?? "Other"
                    let catDuration = categoryActivity.totalActivityDuration

                    var existing = categoryMap[categoryName] ?? (duration: 0, apps: [:])
                    existing.duration += catDuration

                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown"
                        let appDuration = appActivity.totalActivityDuration
                        let appPickups = appActivity.numberOfPickups
                        let appNotifications = appActivity.numberOfNotifications
                        totalPickups += appPickups
                        totalNotifications += appNotifications

                        var appEntry = existing.apps[appName] ?? (duration: 0, pickups: 0, notifications: 0)
                        appEntry.duration += appDuration
                        appEntry.pickups += appPickups
                        appEntry.notifications += appNotifications
                        existing.apps[appName] = appEntry
                    }

                    categoryMap[categoryName] = existing
                }
            }
        }

        let categories = categoryMap.compactMap { name, value -> CategoryUsage? in
            // Skip categories with no meaningful duration (< 30 seconds)
            guard value.duration >= 30 else { return nil }

            let apps = value.apps
                .filter { $0.value.duration >= 30 }
                .map { AppUsage(name: $0.key, duration: $0.value.duration, pickups: $0.value.pickups, notifications: $0.value.notifications) }
                .sorted { $0.duration > $1.duration }
            let topApps = Array(apps.prefix(3))

            return CategoryUsage(
                name: name,
                duration: value.duration,
                apps: topApps
            )
        }.sorted { $0.duration > $1.duration }

        return ActivityReport(
            totalDuration: totalDuration,
            totalPickups: totalPickups,
            totalNotifications: totalNotifications,
            categories: categories
        )
    }
}
