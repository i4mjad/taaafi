import DeviceActivity
import ExtensionKit
import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.taaafi.fort", category: "DeviceActivityReport")

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

@main
struct DeviceActivityReportExtensionMain: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (String) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        logger.info("makeConfiguration called — starting data aggregation")

        var totalSeconds: Double = 0
        var categoryIndex = 0
        var categoryMinutes: [[String: Any]] = []

        for await activityData in data {
            logger.info("Processing activityData entry")
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration
                logger.info("Segment: duration=\(segment.totalActivityDuration)s")

                for await categoryActivity in segment.categories {
                    let mins = Int(categoryActivity.totalActivityDuration / 60)
                    if mins > 0 {
                        categoryMinutes.append([
                            "name": "category_\(categoryIndex)",
                            "minutes": mins
                        ])
                        logger.info("Category \(categoryIndex): \(mins) minutes")
                        categoryIndex += 1
                    }
                }
            }
        }

        let totalMinutes = Int(totalSeconds / 60)
        logger.info("Aggregation done: \(categoryMinutes.count) categories, \(totalMinutes) total minutes")

        // Write to shared UserDefaults for the host app to read
        let report: [String: Any] = [
            "categories": categoryMinutes,
            "totalScreenTimeMinutes": totalMinutes,
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: report),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let defaults = UserDefaults(suiteName: "group.com.taaafi.app")
            defaults?.set(jsonString, forKey: "fortUsageReport")
            defaults?.synchronize()
            logger.info("Wrote usage report to UserDefaults: \(jsonString)")
        } else {
            logger.error("Failed to serialize report to JSON")
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: totalSeconds) ?? "No activity data"
    }
}
