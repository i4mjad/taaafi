//
//  TotalActivityReport.swift
//  DeviceActivityReport
//

import DeviceActivity
import ExtensionKit
import SwiftUI
import FamilyControls

extension DeviceActivityReport.Context {
    // Context for total activity report
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
    let context: DeviceActivityReport.Context = .totalActivity
    
    let content: (ActivityReportConfig) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReportConfig {
        FocusLogger.d("=== TotalActivityReport.makeConfiguration: START ===")
        
        var appUsageList: [AppUsageData] = []
        var totalDuration: TimeInterval = 0
        
        // Process the data from DeviceActivityResults
        for await deviceData in data {
            FocusLogger.d("TotalActivityReport: processing device data")
            
            // Iterate through activity segments
            for segment in deviceData.activitySegments {
                FocusLogger.d("TotalActivityReport: segment duration = \(segment.totalActivityDuration)s")
                totalDuration += segment.totalActivityDuration
                
                // Process individual app activities
                for category in segment.categories {
                    for app in category.applications {
                        let duration = app.totalActivityDuration
                        
                        // Get app token and display info
                        let appToken = app.application
                        let appName = (appToken.localizedDisplayName ?? "Unknown App")
                        let bundleId = appToken.bundleIdentifier ?? "unknown.bundle"
                        
                        FocusLogger.d("TotalActivityReport: app=\(appName), duration=\(duration)s")
                        
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
        appUsageList = Array(appUsageList.prefix(10))
        
        let totalFormatted = formatDuration(totalDuration)
        
        FocusLogger.d("TotalActivityReport: total apps=\(appUsageList.count), total duration=\(totalFormatted)")
        FocusLogger.d("=== TotalActivityReport.makeConfiguration: END ===")
        
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
