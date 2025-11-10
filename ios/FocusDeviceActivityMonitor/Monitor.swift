import DeviceActivity
import Foundation

final class Monitor: DeviceActivityMonitor {

  // Called at the start of a scheduled interval for the given activity
  override func intervalDidStart(for activity: DeviceActivityName) {
    FocusLogger.d("🔴 [EXTENSION] === intervalDidStart: START === activity=\(activity.rawValue)")
    let timestamp = ISO8601DateFormatter().string(from: Date())
    FocusLogger.d("🔴 [EXTENSION] intervalDidStart: timestamp=\(timestamp)")
    updateSnapshot(reason: "intervalStart")
    FocusLogger.d("🔴 [EXTENSION] === intervalDidStart: END ===")
  }

  // Called at the end of a scheduled interval for the given activity
  override func intervalDidEnd(for activity: DeviceActivityName) {
    FocusLogger.d("🔴 [EXTENSION] === intervalDidEnd: START === activity=\(activity.rawValue)")
    let timestamp = ISO8601DateFormatter().string(from: Date())
    FocusLogger.d("🔴 [EXTENSION] intervalDidEnd: timestamp=\(timestamp)")
    updateSnapshot(reason: "intervalEnd")
    FocusLogger.d("🔴 [EXTENSION] === intervalDidEnd: END ===")
  }

  // Called when usage threshold events are reached (real-time updates!)
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    FocusLogger.d("🔴 [EXTENSION] === eventDidReachThreshold: START === event=\(event.rawValue), activity=\(activity.rawValue)")
    let timestamp = ISO8601DateFormatter().string(from: Date())
    FocusLogger.d("🔴 [EXTENSION] eventDidReachThreshold: timestamp=\(timestamp)")
    updateSnapshot(reason: "thresholdReached")
    FocusLogger.d("🔴 [EXTENSION] === eventDidReachThreshold: END ===")
  }
  
  // Centralized snapshot update method
  private func updateSnapshot(reason: String) {
    FocusLogger.d("🔴 [EXTENSION] === updateSnapshot: START === reason=\(reason)")
    
    // Check App Group access
    guard let ud = UserDefaults(suiteName: FocusShared.appGroupId) else {
      FocusLogger.e("🔴 [EXTENSION] updateSnapshot: ❌ ERROR - cannot access app group '\(FocusShared.appGroupId)'")
      return
    }
    FocusLogger.d("🔴 [EXTENSION] updateSnapshot: ✅ app group accessed")
    
    let now = Date()
    let iso = ISO8601DateFormatter()
    let existing = ud.dictionary(forKey: FocusShared.lastSnapshotKey) ?? [:]
    
    FocusLogger.d("🔴 [EXTENSION] updateSnapshot: existing snapshot keys=\(existing.keys.joined(separator: ", "))")

    var apps = (existing["apps"] as? [[String: Any]]) ?? []
    var bucketIndex: Int? = apps.firstIndex { ($0["bundle"] as? String) == "monitored" }
    var minutes = (bucketIndex != nil ? (apps[bucketIndex!]["minutes"] as? Int) : nil) ?? 0
    
    FocusLogger.d("🔴 [EXTENSION] updateSnapshot: existing minutes=\(minutes)")

    // Calculate new minutes based on reason
    if reason == "thresholdReached" {
      minutes += 1
      FocusLogger.d("🔴 [EXTENSION] updateSnapshot: threshold reached, incremented to \(minutes) minutes")
    } else if let lastUpdateStr = existing["lastUpdate"] as? String, let lastDate = iso.date(from: lastUpdateStr) {
      let delta = Int(now.timeIntervalSince(lastDate) / 60.0)
      if delta > 0 { 
        minutes += delta 
        FocusLogger.d("🔴 [EXTENSION] updateSnapshot: time elapsed since last update, added \(delta) minutes, total=\(minutes)")
      }
    } else {
      FocusLogger.d("🔴 [EXTENSION] updateSnapshot: no previous update time, starting fresh")
    }

    let monitored: [String: Any] = [
      "bundle": "monitored",
      "label": "Monitored Apps",
      "minutes": minutes
    ]
    
    if let idx = bucketIndex {
      apps[idx] = monitored
      FocusLogger.d("🔴 [EXTENSION] updateSnapshot: updated existing app entry at index \(idx)")
    } else {
      apps.append(monitored)
      FocusLogger.d("🔴 [EXTENSION] updateSnapshot: added new app entry")
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
    
    FocusLogger.d("🔴 [EXTENSION] updateSnapshot: saving snapshot with \(apps.count) apps")
    ud.set(snapshot, forKey: FocusShared.lastSnapshotKey)
    FocusLogger.d("🔴 [EXTENSION] updateSnapshot: ✅ snapshot saved successfully")
    FocusLogger.d("🔴 [EXTENSION] === updateSnapshot: END ===")
  }
}
