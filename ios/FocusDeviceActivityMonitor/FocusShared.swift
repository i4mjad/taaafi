//
//  FocusShared.swift
//  FocusDeviceActivityMonitor
//
//  Shared constants for Focus feature
//

import Foundation
import DeviceActivity

enum FocusShared {
    static let appGroupId = "group.com.taaafi.app"
    static let lastSnapshotKey = "FocusLastSnapshot"
}

extension DeviceActivityName {
    static let everyHour = Self("everyHour")
}
