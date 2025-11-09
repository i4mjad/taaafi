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

