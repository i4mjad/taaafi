import DeviceActivity
import Foundation

final class Monitor: DeviceActivityMonitor {
    override func intervalDidEnd(for context: DeviceActivityMonitor.Context) {
        // Minimal snapshot — extend later with permitted aggregates
        let snapshot: [String: Any] = [
            "apps": [],              // fill later when you compute app totals
            "domains": [],           // fill later when you compute domain totals
            "pickups": 0,            // compute if you adopt pickups signals
            "notifications": NSNull(),
            "generatedAt": Int(Date().timeIntervalSince1970)
        ]
        if let ud = UserDefaults(suiteName: FocusShared.appGroupId) {
            ud.set(snapshot, forKey: FocusShared.lastSnapshotKey)
        }
    }
}
