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
    
    // Best-effort aggregation:
    // We increment a single "Monitored Apps" bucket by 1 minute on threshold events,
    // and on interval boundaries we add the elapsed minutes since the last update.
    let ud = UserDefaults(suiteName: FocusShared.appGroupId)
    let now = Date()
    let iso = ISO8601DateFormatter()
    let existing = ud?.dictionary(forKey: FocusShared.lastSnapshotKey) ?? [:]

    var apps = (existing["apps"] as? [[String: Any]]) ?? []
    var bucketIndex: Int? = apps.firstIndex { ($0["bundle"] as? String) == "monitored" }
    var minutes = (bucketIndex != nil ? (apps[bucketIndex!]["minutes"] as? Int) : nil) ?? 0

    if reason == "thresholdReached" {
      minutes += 1
    } else if let lastUpdateStr = existing["lastUpdate"] as? String, let lastDate = iso.date(from: lastUpdateStr) {
      let delta = Int(now.timeIntervalSince(lastDate) / 60.0)
      if delta > 0 { minutes += delta }
    }

    let monitored: [String: Any] = [
      "bundle": "monitored",
      "label": "Monitored Apps",
      "minutes": minutes
    ]
    if let idx = bucketIndex {
      apps[idx] = monitored
    } else {
      apps.append(monitored)
    }

    let snapshot: [String: Any] = [
      "apps": apps,
      "domains": existing["domains"] ?? [],
      "pickups": existing["pickups"] ?? 0,
      "notifications": existing["notifications"] ?? NSNull(),
      "generatedAt": Int(now.timeIntervalSince1970),
      "updateReason": reason,
      "lastUpdate": iso.string(from: now)
    ]
    
    UserDefaults(suiteName: FocusShared.appGroupId)?
      .set(snapshot, forKey: FocusShared.lastSnapshotKey)
      
    FocusLogger.d("Monitor.updateSnapshot saved", snapshot)
  }
}
