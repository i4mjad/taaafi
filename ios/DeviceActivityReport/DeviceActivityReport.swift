//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//
//  Main entry point for the DeviceActivityReport extension
//  Registers all report scenes that can be displayed
//

import DeviceActivity
import ExtensionKit
import SwiftUI

/// Main extension struct
/// @main marks this as the entry point for the extension
@main
struct FocusActivityReportExtension: DeviceActivityReportExtension {
    /// Body returns all report scenes this extension provides
    /// The system calls the appropriate scene based on context
    var body: some DeviceActivityReportScene {
        // Register TotalActivityReport scene
        // The closure receives the formatted string from makeConfiguration()
        // and passes it to TotalActivityView for display
        return TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}
