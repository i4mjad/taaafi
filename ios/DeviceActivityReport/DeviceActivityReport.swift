//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//
//  Main entry point for DeviceActivityReport extension
//  This extension generates visual reports of Screen Time usage data
//

import DeviceActivity
import SwiftUI

/// Main extension struct that registers all report scenes
/// @main indicates this is the entry point for the extension
@main
struct FocusActivityReportExtension: DeviceActivityReportExtension {
    /// Returns the collection of report scenes this extension provides
    /// Each scene represents a different way to visualize the data
    var body: some DeviceActivityReportScene {
        FocusLogger.d("🟢 [EXTENSION MAIN] === Extension body called ===")
        
        // Register the total activity report scene
        // This scene will be used when the app requests data with .totalActivity context
        return TotalActivityReport { config in
            TotalActivityView(config: config)
        }
    }
}
