//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct DeviceActivityReportExt: DeviceActivityReportExtension {
    @MainActor var body: some DeviceActivityReportScene {
        TotalActivityReport { report in
            TotalActivityView(report: report)
        }
    }
}
