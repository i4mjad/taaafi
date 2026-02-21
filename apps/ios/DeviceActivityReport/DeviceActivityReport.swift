//
//  DeviceActivityReport.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import DeviceActivity
import ExtensionKit
import SwiftUI
import os

// #region agent log
private let dbg = Logger(subsystem: "com.taaafi.debug", category: "86f59f")
// #endregion

@main
struct DeviceActivityReportExt: DeviceActivityReportExtension {
    // #region agent log
    init() {
        dbg.notice("[H1] ext_process_init")
    }
    // #endregion

    @MainActor var body: some DeviceActivityReportScene {
        TotalActivityReport { report in
            TotalActivityView(report: report)
        }
    }
}
