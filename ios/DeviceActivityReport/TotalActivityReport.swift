//
//  TotalActivityReport.swift
//  DeviceActivityReport
//

import DeviceActivity
import SwiftUI
import FamilyControls

// Define custom context for our report
extension DeviceActivity.DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

// Configuration structure to pass to the view
struct ActivityReportConfig {
    var apps: [AppUsageData]
    var totalScreenTime: String
    var date: Date
}

struct AppUsageData: Identifiable {
    let id = UUID()
    let name: String
    let bundle: String
    let duration: TimeInterval
    let durationFormatted: String
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivity.DeviceActivityReport.Context = .totalActivity
    
    let content: (ActivityReportConfig) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReportConfig {
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: START ===")
        
        var appUsageList: [AppUsageData] = []
        var totalDuration: TimeInterval = 0
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: processing activity data...")
        
        // Process each user's activity data
        let activities = data.map { $0 }
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: found \(activities.count) activity records")
        
        for activityData in activities {
            FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: processing activity segments...")
            
            // Process activity segments
            for segment in activityData.activitySegments {
                let segmentDuration = segment.totalActivityDuration
                totalDuration += segmentDuration
                FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: segment duration = \(Int(segmentDuration))s")
                
                // Process categories within segment
                for category in segment.categories {
                    FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: category with \(category.applications.count) apps")
                    
                    // Process individual apps
                    for appActivity in category.applications {
                        let duration = appActivity.totalActivityDuration
                        let appToken = appActivity.application
                        let appName = appToken.localizedDisplayName ?? "Unknown App"
                        let bundleId = appToken.bundleIdentifier ?? "unknown.bundle"
                        
                        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: app=\(appName), duration=\(Int(duration))s")
                        
                        let formatted = formatDuration(duration)
                        
                        appUsageList.append(AppUsageData(
                            name: appName,
                            bundle: bundleId,
                            duration: duration,
                            durationFormatted: formatted
                        ))
                    }
                }
            }
        }
        
        // Sort by duration (highest first)
        appUsageList.sort { $0.duration > $1.duration }
        
        // Take top 10 apps
        let originalCount = appUsageList.count
        appUsageList = Array(appUsageList.prefix(10))
        
        let totalFormatted = formatDuration(totalDuration)
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: ✅ processed \(originalCount) apps, showing top \(appUsageList.count)")
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: total screen time = \(totalFormatted)")
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: END ===")
        
        return ActivityReportConfig(
            apps: appUsageList,
            totalScreenTime: totalFormatted,
            date: Date()
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}
