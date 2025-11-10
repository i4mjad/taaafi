//
//  TotalActivityReport.swift
//  DeviceActivityReport
//
//  Report scene that processes Screen Time usage data
//  This is called by the system when DeviceActivityReport widget needs to render
//

import DeviceActivity
import ExtensionKit
import SwiftUI

/// Define custom context identifier for this report
/// This context is referenced when creating DeviceActivityReport() in Flutter
extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

/// Report scene implementation
/// Processes raw Screen Time data and returns formatted string for display
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
        
        // Iterate through all activity data (async iteration required)
        // DeviceActivityResults is an AsyncSequence
        for await deviceData in data {
            FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: processing device data")
            
            // activitySegments is ALSO an AsyncSequence - use for await here too!
            for await segment in deviceData.activitySegments {
                let duration = segment.totalActivityDuration
                totalDuration += duration
                FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: segment duration=\(Int(duration))s")
            }
        }
        
        // Format the total duration for display
        let formatted = formatter.string(from: totalDuration) ?? "No activity data"
        
        FocusLogger.d("🟢 [REPORT SCENE] makeConfiguration: ✅ total duration=\(formatted)")
        FocusLogger.d("🟢 [REPORT SCENE] === makeConfiguration: END ===")
        
        return formatted
    }
}
