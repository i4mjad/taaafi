//
//  TotalActivityReport.swift
//  DeviceActivityReport
//
//  Report scene that processes Screen Time usage data
//  This is called by the system when DeviceActivityReport widget needs to render
//  ENHANCED: Now extracts per-app usage and saves to App Group for Flutter
//

import DeviceActivity
import ExtensionKit
import SwiftUI
import ManagedSettings

/// Define custom context identifier for this report
/// This context is referenced when creating DeviceActivityReport() in Flutter
extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

/// Report scene implementation
/// Processes raw Screen Time data and returns formatted string for display
/// ALSO extracts per-app usage data and saves to App Group storage
struct TotalActivityReport: DeviceActivityReportScene {
    /// Context identifier - must match usage in Flutter code
    let context: DeviceActivityReport.Context = .totalActivity
    
    /// View builder closure - creates SwiftUI view from formatted string
    let content: (String) -> TotalActivityView
    
    /// Processes activity data into a configuration string
    /// This is the main method called by the system to generate report content
    ///
    /// - Parameter data: DeviceActivityResults containing usage information
    /// - Returns: Formatted duration string (e.g., "3h 45m")
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: START ===")
        
        // Setup formatter for consistent time formatting
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        
        // Calculate total activity duration by summing all segments
        var totalDuration: TimeInterval = 0
        
        // NEW: Track per-app usage with category information
        var appUsageMap: [String: (label: String, category: String, duration: TimeInterval)] = [:]
        
        // Iterate through all activity data (async iteration required)
        // DeviceActivityResults is an AsyncSequence
        for await deviceData in data {
            FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: processing device data")
            
            // activitySegments is ALSO an AsyncSequence - use for await here too!
            for await segment in deviceData.activitySegments {
                let duration = segment.totalActivityDuration
                totalDuration += duration
                FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: segment duration=\(Int(duration))s")
                
                // NEW: Extract per-app usage from this segment
                for await activity in segment.categories {
                    // Process category-level activities (e.g., Social, Entertainment)
                    let categoryToken = activity.category
                    let categoryName = categoryToken.localizedDisplayName ?? "Other"
                    
                    FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: category=\(categoryName)")
                    
                    for await app in activity.applications {
                        let appToken = app.application
                        let appDuration = app.totalDuration
                        
                        // Get app label (bundle identifier as fallback)
                        let bundleId = appToken.bundleIdentifier ?? "unknown"
                        let appLabel = appToken.localizedDisplayName ?? bundleId
                        
                        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: app=\(appLabel), category=\(categoryName), duration=\(Int(appDuration))s")
                        
                        // Accumulate usage per app (now with category info)
                        if let existing = appUsageMap[bundleId] {
                            appUsageMap[bundleId] = (label: appLabel, category: categoryName, duration: existing.duration + appDuration)
                        } else {
                            appUsageMap[bundleId] = (label: appLabel, category: categoryName, duration: appDuration)
                        }
                    }
                }
            }
        }
        
        // Format the total duration for display
        let formatted = formatter.string(from: totalDuration) ?? "No activity data"
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: ✅ total duration=\(formatted)")
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: found \(appUsageMap.count) unique apps")
        
        // NEW: Save per-app data to App Group storage for Flutter
        savePerAppUsageToAppGroup(apps: appUsageMap, totalDuration: totalDuration)
        
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: END ===")
        
        return formatted
    }
    
    /// Saves per-app usage data to App Group storage for Flutter to access
    /// - Parameters:
    ///   - apps: Dictionary of bundle ID to (label, category, duration)
    ///   - totalDuration: Total screen time across all apps
    private func savePerAppUsageToAppGroup(
        apps: [String: (label: String, category: String, duration: TimeInterval)],
        totalDuration: TimeInterval
    ) {
        FocusLogger.d("🟢 [REPORT SCENE] === savePerAppUsageToAppGroup: START ===")
        
        guard let ud = UserDefaults(suiteName: FocusShared.appGroupId) else {
            FocusLogger.e("🟢 [REPORT SCENE] savePerAppUsageToAppGroup: ❌ ERROR - cannot access app group '\(FocusShared.appGroupId)'")
            return
        }
        
        // Convert to array format for Flutter
        let appsArray: [[String: Any]] = apps.map { (bundleId, appInfo) in
            return [
                "bundle": bundleId,
                "label": appInfo.label,
                "category": appInfo.category, // NOW INCLUDES CATEGORY!
                "minutes": Int(appInfo.duration / 60.0) // Convert seconds to minutes
            ]
        }.sorted { (a, b) in
            // Sort by minutes descending (most used first)
            let aMinutes = a["minutes"] as? Int ?? 0
            let bMinutes = b["minutes"] as? Int ?? 0
            return aMinutes > bMinutes
        }
        
        let now = Date()
        let snapshot: [String: Any] = [
            "apps": appsArray,
            "domains": [], // Web usage not tracked in this implementation
            "pickups": 0,  // Not available in DeviceActivityReport
            "notifications": NSNull(),
            "generatedAt": Int(now.timeIntervalSince1970),
            "updateReason": "deviceActivityReport",
            "lastUpdate": ISO8601DateFormatter().string(from: now),
            "totalMinutes": Int(totalDuration / 60.0)
        ]
        
        FocusLogger.d("🟢 [REPORT SCENE] savePerAppUsageToAppGroup: saving \(appsArray.count) apps, total=\(Int(totalDuration/60))min")
        
        ud.set(snapshot, forKey: FocusShared.lastSnapshotKey)
        ud.synchronize() // Force immediate write
        
        FocusLogger.d("🟢 [REPORT SCENE] savePerAppUsageToAppGroup: ✅ snapshot saved successfully")
        FocusLogger.d("🟢 [REPORT SCENE] === savePerAppUsageToAppGroup: END ===")
    }
}
