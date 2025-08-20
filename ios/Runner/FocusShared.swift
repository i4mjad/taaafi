//
//  FocusShared.swift
//  Runner
//
//  Created by Amjad Khalfan on 16/08/2025.
//


import Foundation
import DeviceActivity

enum FocusShared {
  static let appGroupId = "group.com.taaafi.app"
  static let lastSnapshotKey = "FocusLastSnapshot"
  static let logsKey = "FocusLogs"
}

extension DeviceActivityName {
    static let everyHour = Self("everyHour")
    static let realtimeUpdates = Self("realtimeUpdates")
}

extension DeviceActivityEvent.Name {
    static let usageThreshold = Self("usageThreshold")
}

// MARK: - Shared helpers

extension FocusShared {
  /// Append a log line into the shared App Group log buffer (capped to 200 lines)
  static func appendLog(_ line: String) {
    let ud = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard // Simulator fallback
    var logs = ud.stringArray(forKey: logsKey) ?? []
    logs.append(line)
    if logs.count > 200 {
      logs.removeFirst(logs.count - 200)
    }
    ud.set(logs, forKey: logsKey)
  }
}

