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
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (ActivityReport) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        let classificationMap = CategoryClassification.current()

        var totalDuration: TimeInterval = 0
        var totalPickups = 0
        var totalNotifications = 0
        var categoryMap: [String: (duration: TimeInterval, apps: [String: (duration: TimeInterval, pickups: Int, notifications: Int)])] = [:]
        var hourlyMap: [Int: (safe: TimeInterval, threat: TimeInterval)] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration
                let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)

                for await categoryActivity in segment.categories {
                    let categoryName = categoryActivity.category.localizedDisplayName ?? "Other"
                    let catDuration = categoryActivity.totalActivityDuration
                    let cls = classificationMap[categoryName] ?? .neutral

                    // Accumulate hourly safe/threat
                    var hourEntry = hourlyMap[hour] ?? (safe: 0, threat: 0)
                    switch cls {
                    case .safe: hourEntry.safe += catDuration
                    case .threat: hourEntry.threat += catDuration
                    case .neutral: break
                    }
                    hourlyMap[hour] = hourEntry

                    // Category aggregation
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

        // Build categories with classification
        let categories = categoryMap.compactMap { name, value -> CategoryUsage? in
            guard value.duration >= 30 else { return nil }

            let apps = value.apps
                .filter { $0.value.duration >= 30 }
                .map { AppUsage(name: $0.key, duration: $0.value.duration, pickups: $0.value.pickups, notifications: $0.value.notifications) }
                .sorted { $0.duration > $1.duration }
            let topApps = Array(apps.prefix(3))
            let cls = classificationMap[name] ?? .neutral

            return CategoryUsage(
                name: name,
                duration: value.duration,
                apps: topApps,
                classification: cls
            )
        }.sorted { $0.duration > $1.duration }

        // Compute guard score
        let safeDuration = categories.filter { $0.classification == .safe }.reduce(0) { $0 + $1.duration }
        let threatDuration = categories.filter { $0.classification == .threat }.reduce(0) { $0 + $1.duration }
        let total = safeDuration + threatDuration
        let guardScore = total > 0 ? Int((safeDuration / total) * 100) : 100

        // Build hourly breakdown (0-23)
        let hourlyBreakdown = (0...23).map { hour in
            let entry = hourlyMap[hour] ?? (safe: 0, threat: 0)
            return HourlyUsage(id: hour, hour: hour, safeDuration: entry.safe, threatDuration: entry.threat)
        }

        return ActivityReport(
            totalDuration: totalDuration,
            totalPickups: totalPickups,
            totalNotifications: totalNotifications,
            categories: categories,
            guardScore: guardScore,
            safeDuration: safeDuration,
            threatDuration: threatDuration,
            hourlyBreakdown: hourlyBreakdown
        )
    }
}
