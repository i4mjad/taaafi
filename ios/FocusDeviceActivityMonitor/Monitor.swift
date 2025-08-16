import DeviceActivity
import Foundation

final class Monitor: DeviceActivityMonitor {

  // Called at the start of a scheduled interval for the given activity
  override func intervalDidStart(for activity: DeviceActivityName) {
    FocusLogger.d("Monitor.intervalDidStart \(activity.rawValue)")
  }

  // Called at the end of a scheduled interval for the given activity
  override func intervalDidEnd(for activity: DeviceActivityName) {
    FocusLogger.d("Monitor.intervalDidEnd \(activity.rawValue)")
    
    let snapshot: [String: Any] = [
      "apps": [],
      "domains": [],
      "pickups": 0,
      "notifications": NSNull(),
      "generatedAt": Int(Date().timeIntervalSince1970)
    ]
    
    UserDefaults(suiteName: FocusShared.appGroupId)?
      .set(snapshot, forKey: FocusShared.lastSnapshotKey)
      
    FocusLogger.d("Monitor.intervalDidEnd snapshot saved", snapshot)
  }

  // (Optional) if you later add events/thresholds
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, for activity: DeviceActivityName) {
    FocusLogger.d("Monitor.eventDidReachThreshold \(event.rawValue) for \(activity.rawValue)")
  }
}
