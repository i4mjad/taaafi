import DeviceActivity
import Foundation
import os.log

private let logger = Logger(subsystem: "com.taaafi.fort", category: "Monitor")
private let suiteName = "group.com.taaafi.app"
private let usageKey = "fortMonitorUsage"

/// Monitors device activity schedule events.
/// Writes usage threshold crossings to app group UserDefaults
/// so the host app can read approximate screen time.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.info("intervalDidStart: \(activity.rawValue)")
        writeEvent("intervalStart", activity: activity.rawValue, minutes: 0)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.info("intervalDidEnd: \(activity.rawValue)")
        writeEvent("intervalEnd", activity: activity.rawValue, minutes: 0)
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.info("eventDidReachThreshold: \(event.rawValue) activity=\(activity.rawValue)")

        // Parse minutes from event name (format: "totalUsage_30")
        let parts = event.rawValue.split(separator: "_")
        let minutes = parts.count >= 2 ? Int(parts.last!) ?? 0 : 0

        writeEvent("threshold", activity: activity.rawValue, minutes: minutes)

        // Update the running total — the highest threshold reached IS approximate usage
        if let data = defaults?.data(forKey: usageKey),
           var report = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let current = report["totalScreenTimeMinutes"] as? Int ?? 0
            if minutes > current {
                report["totalScreenTimeMinutes"] = minutes
                report["date"] = ISO8601DateFormatter().string(from: Date())
                if let updated = try? JSONSerialization.data(withJSONObject: report) {
                    defaults?.set(updated, forKey: usageKey)
                    logger.info("Updated usage to \(minutes) minutes")
                }
            }
        } else {
            // First write
            let report: [String: Any] = [
                "totalScreenTimeMinutes": minutes,
                "categories": [] as [[String: Any]],
                "pickups": 0,
                "date": ISO8601DateFormatter().string(from: Date())
            ]
            if let data = try? JSONSerialization.data(withJSONObject: report) {
                defaults?.set(data, forKey: usageKey)
                logger.info("Created initial usage report at \(minutes) minutes")
            }
        }
    }

    private func writeEvent(_ type: String, activity: String, minutes: Int) {
        let eventKey = "fortMonitorEvents"
        var events = defaults?.array(forKey: eventKey) as? [[String: Any]] ?? []
        events.append([
            "type": type,
            "activity": activity,
            "minutes": minutes,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
        // Keep last 100 events
        if events.count > 100 { events = Array(events.suffix(100)) }
        defaults?.set(events, forKey: eventKey)
    }
}
