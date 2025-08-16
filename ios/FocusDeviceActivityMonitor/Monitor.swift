import DeviceActivity
import Foundation

final class Monitor: DeviceActivityMonitor {

  // Called at the start of a scheduled interval for the given activity
  override func intervalDidStart(for activity: DeviceActivityName) {
    FocusLogger.d("Monitor.intervalDidStart \(activity.rawValue)")
    updateSnapshot(reason: "intervalStart")
  }

  // Called at the end of a scheduled interval for the given activity
  override func intervalDidEnd(for activity: DeviceActivityName) {
    FocusLogger.d("Monitor.intervalDidEnd \(activity.rawValue)")
    updateSnapshot(reason: "intervalEnd")
  }

  // Called when usage threshold events are reached (real-time updates!)
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    FocusLogger.d("Monitor.eventDidReachThreshold \(event.rawValue) for \(activity.rawValue)")
    updateSnapshot(reason: "thresholdReached")
  }
  
  // Centralized snapshot update method
  private func updateSnapshot(reason: String) {
    FocusLogger.d("Monitor.updateSnapshot reason=\(reason)")
    
    // Create more detailed snapshot with timestamp and reason
    let snapshot: [String: Any] = [
      "apps": [], // TODO: Real app data would go here if available
      "domains": [],
      "pickups": 0, // TODO: Could be tracked separately
      "notifications": NSNull(),
      "generatedAt": Int(Date().timeIntervalSince1970),
      "updateReason": reason,
      "lastUpdate": ISO8601DateFormatter().string(from: Date())
    ]
    
    UserDefaults(suiteName: FocusShared.appGroupId)?
      .set(snapshot, forKey: FocusShared.lastSnapshotKey)
      
    FocusLogger.d("Monitor.updateSnapshot saved", snapshot)
  }
}
