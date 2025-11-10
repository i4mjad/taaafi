//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//

import DeviceActivity
import SwiftUI

@main
struct FocusActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for total activity
        TotalActivityReport { config in
            TotalActivityView(config: config)
        }
    }
}
