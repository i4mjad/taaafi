//
//  TotalActivityReport.swift
//  DeviceActivityReport
//
//  Report scene that processes and formats Screen Time usage data
//

import DeviceActivity
import SwiftUI
import FamilyControls

/// Define a custom context identifier for our total activity report
/// This context is used to reference this specific report scene
extension DeviceActivity.DeviceActivityReport.Context {
    /// Context identifier for showing total daily activity
    static let totalActivity = Self("Total Activity")
}

// MARK: - Data Models

/// Configuration data structure passed from report processing to the view
/// Contains all formatted data needed to render the UI
struct ActivityReportConfig {
    /// List of apps with their usage data, sorted by duration
    var apps: [AppUsageData]
    
    /// Formatted string of total screen time (e.g., "3h 45m")
    var totalScreenTime: String
    
    /// Date this report represents
    var date: Date
}

/// Individual app usage data
struct AppUsageData: Identifiable {
    let id = UUID()
    
    /// Display name of the app (e.g., "Instagram")
    let name: String
    
    /// Bundle identifier (e.g., "com.burbn.instagram")
    let bundle: String
    
    /// Total usage duration in seconds
    let duration: TimeInterval
    
    /// Human-readable formatted duration (e.g., "1h 30m")
    let durationFormatted: String
}

// MARK: - Report Scene Implementation

/// Report scene that processes DeviceActivity data and generates configuration for the view
/// Conforms to DeviceActivityReportScene protocol which requires:
/// - context: identifies this scene
/// - content: closure that creates the view from configuration
/// - makeConfiguration: async function that processes raw data into configuration
struct TotalActivityReport: DeviceActivityReportScene {
    /// The context identifier for this report scene
    /// Must match the context used when creating DeviceActivityReport() in Flutter
    let context: DeviceActivity.DeviceActivityReport.Context = .totalActivity
    
    /// Closure that creates the SwiftUI view from processed configuration data
    /// This allows the scene to generate different views based on the data
    let content: (ActivityReportConfig) -> TotalActivityView
    
    /// Processes raw DeviceActivityResults into a displayable configuration
    /// This method is called by the system when the report needs to be rendered
    ///
    /// - Parameter data: DeviceActivityResults containing usage data for all users/devices
    /// - Returns: ActivityReportConfig with processed and formatted data for the view
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReportConfig {
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: START ===")
        
        var appUsageList: [AppUsageData] = []
        var totalDuration: TimeInterval = 0
        var recordCount = 0
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: iterating through activity data...")
        
        // DeviceActivityResults is an AsyncSequence, so we use 'for await'
        // Each iteration gives us usage data for one user
        for await activityData in data {
            recordCount += 1
            FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: processing record #\(recordCount)")
            
            // Each activityData contains segments (e.g., daily segments)
            let segmentCount = activityData.activitySegments.count
            FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: record has \(segmentCount) segments")
            
            // Process each time segment
            for segment in activityData.activitySegments {
                let segmentDuration = segment.totalActivityDuration
                totalDuration += segmentDuration
                FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: segment duration = \(Int(segmentDuration))s")
                
                // Each segment contains categories (e.g., Social, Games, etc.)
                let categoryCount = segment.categories.count
                FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: segment has \(categoryCount) categories")
                
                // Process each category
                for category in segment.categories {
                    let appCount = category.applications.count
                    FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: category with \(appCount) apps")
                    
                    // Process individual apps within the category
                    for appActivity in category.applications {
                        let duration = appActivity.totalActivityDuration
                        
                        // Get app information (tokens are opaque for privacy)
                        let appToken = appActivity.application
                        let appName = appToken.localizedDisplayName ?? "Unknown App"
                        let bundleId = appToken.bundleIdentifier ?? "unknown.bundle"
                        
                        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: app=\(appName), duration=\(Int(duration))s")
                        
                        let formatted = formatDuration(duration)
                        
                        // Add to our list
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
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: finished processing \(recordCount) records")
        
        // Sort apps by usage duration (highest first)
        appUsageList.sort { $0.duration > $1.duration }
        
        // Limit to top 10 apps for display
        let originalCount = appUsageList.count
        appUsageList = Array(appUsageList.prefix(10))
        
        // Format total screen time
        let totalFormatted = formatDuration(totalDuration)
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: ✅ processed \(originalCount) apps, showing top \(appUsageList.count)")
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: total screen time = \(totalFormatted)")
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: END ===")
        
        // Return configuration that will be passed to the view
        return ActivityReportConfig(
            apps: appUsageList,
            totalScreenTime: totalFormatted,
            date: Date()
        )
    }
    
    /// Formats a duration in seconds into a human-readable string
    /// - Parameter duration: Time interval in seconds
    /// - Returns: Formatted string like "2h 30m" or "45m" or "< 1m"
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
