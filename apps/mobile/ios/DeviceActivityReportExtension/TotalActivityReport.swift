import DeviceActivity
import ExtensionKit
import SwiftUI

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
        var totalSeconds: Double = 0
        var categoryIndex = 0
        var categoryMinutes: [[String: Any]] = []

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    let mins = Int(categoryActivity.totalActivityDuration / 60)
                    if mins > 0 {
                        categoryMinutes.append([
                            "name": "category_\(categoryIndex)",
                            "minutes": mins
                        ])
                        categoryIndex += 1
                    }
                }
            }
        }

        // Write to shared UserDefaults for the host app to read
        let report: [String: Any] = [
            "categories": categoryMinutes,
            "totalScreenTimeMinutes": Int(totalSeconds / 60),
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: report),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults(suiteName: "group.com.taaafi.app")?.set(jsonString, forKey: "fortUsageReport")
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: totalSeconds) ?? "No activity data"
    }
}
