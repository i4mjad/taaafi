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
    static let totalActivity = Self("total-activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (ActivityReport) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        let classificationMap = CategoryClassification.current()

        var totalDuration: TimeInterval = 0
        var totalPickups = 0
        var totalNotifications = 0
        var appMap: [String: (category: String, duration: TimeInterval, pickups: Int, notifications: Int)] = [:]
        var hourlyMap: [Int: (safe: TimeInterval, threat: TimeInterval)] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration
                let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)

                for await categoryActivity in segment.categories {
                    let categoryName = categoryActivity.category.localizedDisplayName ?? "Other"
                    let cls = classificationMap[categoryName] ?? .neutral

                    var hourEntry = hourlyMap[hour] ?? (safe: 0, threat: 0)
                    switch cls {
                    case .safe: hourEntry.safe += categoryActivity.totalActivityDuration
                    case .threat: hourEntry.threat += categoryActivity.totalActivityDuration
                    case .neutral: break
                    }
                    hourlyMap[hour] = hourEntry

                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown"
                        let appDuration = appActivity.totalActivityDuration
                        let appPickups = appActivity.numberOfPickups
                        let appNotifications = appActivity.numberOfNotifications
                        totalPickups += appPickups
                        totalNotifications += appNotifications

                        var entry = appMap[appName] ?? (category: categoryName, duration: 0, pickups: 0, notifications: 0)
                        entry.duration += appDuration
                        entry.pickups += appPickups
                        entry.notifications += appNotifications
                        appMap[appName] = entry
                    }
                }
            }
        }

        let apps = appMap
            .filter { $0.value.duration >= 30 }
            .map { name, val in
                AppDetail(
                    name: name,
                    categoryName: val.category,
                    duration: val.duration,
                    pickups: val.pickups,
                    notifications: val.notifications,
                    classification: classificationMap[val.category] ?? .neutral
                )
            }
            .sorted { $0.duration > $1.duration }

        let safeDuration = apps.filter { $0.classification == .safe }.reduce(0) { $0 + $1.duration }
        let threatDuration = apps.filter { $0.classification == .threat }.reduce(0) { $0 + $1.duration }
        let total = safeDuration + threatDuration
        let guardScore = total > 0 ? Int((safeDuration / total) * 100) : 100

        let hourlyBreakdown = (0...23).map { hour in
            let entry = hourlyMap[hour] ?? (safe: 0, threat: 0)
            return HourlyUsage(id: hour, hour: hour, safeDuration: entry.safe, threatDuration: entry.threat)
        }

        return ActivityReport(
            totalDuration: totalDuration,
            totalPickups: totalPickups,
            totalNotifications: totalNotifications,
            apps: apps,
            guardScore: guardScore,
            safeDuration: safeDuration,
            threatDuration: threatDuration,
            hourlyBreakdown: hourlyBreakdown
        )
    }
}
