//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct DeviceActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for total activity
        TotalActivityReport { config in
            TotalActivityView(config: config)
        }
    }
}
