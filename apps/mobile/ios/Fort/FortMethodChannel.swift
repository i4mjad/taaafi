import Flutter
import UIKit
import FamilyControls
import DeviceActivity
import os.log

private let logger = Logger(subsystem: "com.taaafi.fort", category: "FortMethodChannel")

/// Main MethodChannel handler for the Fort feature on iOS.
class FortMethodChannel: NSObject {
    static let channelName = "com.taaafi.fort"

    private let familyControlsManager = FamilyControlsManager()

    func register(with messenger: FlutterBinaryMessenger) {
        logger.info("Registering FortMethodChannel on \(Self.channelName)")
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        logger.info("Dart→iOS: \(call.method)")
        switch call.method {
        case "ios_checkFamilyControlsAuth":
            checkFamilyControlsAuth(result: result)
        case "ios_requestFamilyControlsAuth":
            requestFamilyControlsAuth(result: result)
        case "ios_getUsageReport":
            getUsageReport(result: result)
        case "ios_startMonitoring":
            startMonitoring(result: result)
        case "ios_getMonitorEvents":
            getMonitorEvents(result: result)
        default:
            logger.warning("iOS→Dart: \(call.method) NOT_IMPLEMENTED")
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FamilyControls Auth

    private func checkFamilyControlsAuth(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            logger.info("checkAuth status=\(String(describing: status))")
            result(status == .approved)
        } else {
            result(false)
        }
    }

    private func requestFamilyControlsAuth(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            logger.info("Requesting FamilyControls auth...")
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let status = AuthorizationCenter.shared.authorizationStatus
                    logger.info("requestAuth status=\(String(describing: status))")
                    result(status == .approved)
                } catch {
                    logger.error("requestAuth ERROR: \(error.localizedDescription)")
                    result(false)
                }
            }
        } else {
            result(false)
        }
    }

    // MARK: - Monitoring

    /// Schedule daily device activity monitoring with threshold events.
    /// The DeviceActivityMonitor extension writes threshold crossings
    /// to app group UserDefaults — the ONLY way to get data out on iOS.
    private func startMonitoring(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            let center = DeviceActivityCenter()

            // Daily schedule: midnight to 23:59, repeating
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )

            // Threshold events at progressive intervals for total device usage.
            // Pass empty sets for apps/categories/webDomains + includesPastActivity
            // to monitor ALL device activity.
            let thresholds: [Int] = [1, 5, 15, 30, 45, 60, 90, 120, 150, 180, 240, 300, 360, 480]
            var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
            for mins in thresholds {
                let name = DeviceActivityEvent.Name("totalUsage_\(mins)")
                events[name] = DeviceActivityEvent(
                    applications: [],
                    categories: [],
                    webDomains: [],
                    threshold: DateComponents(minute: mins)
                )
            }

            do {
                // Stop existing monitoring first
                center.stopMonitoring([DeviceActivityName("dailyFort")])

                try center.startMonitoring(
                    DeviceActivityName("dailyFort"),
                    during: schedule,
                    events: events
                )
                logger.info("Started daily monitoring with \(events.count) threshold events")
                result(true)
            } catch {
                logger.error("Failed to start monitoring: \(error.localizedDescription)")
                result(false)
            }
        } else {
            result(false)
        }
    }

    // MARK: - Usage Report (reads from Monitor data)

    /// Reads usage data written by DeviceActivityMonitor extension.
    private func getUsageReport(result: @escaping FlutterResult) {
        let suiteName = "group.com.taaafi.app"
        let defaults = UserDefaults(suiteName: suiteName)

        // Try monitor data first (the reliable source)
        if let data = defaults?.data(forKey: "fortMonitorUsage"),
           let str = String(data: data, encoding: .utf8) {
            logger.info("iOS→Dart: returning monitor usage data, length=\(str.count)")
            result(str)
            return
        }

        logger.warning("iOS→Dart: no monitor data yet — returning empty")
        let empty: [String: Any] = [
            "categories": [] as [[String: Any]],
            "totalScreenTimeMinutes": 0,
            "pickups": 0,
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        if let data = try? JSONSerialization.data(withJSONObject: empty),
           let str = String(data: data, encoding: .utf8) {
            result(str)
        } else {
            result(nil)
        }
    }

    /// Returns the raw event log from the monitor extension for diagnostics.
    private func getMonitorEvents(result: @escaping FlutterResult) {
        let defaults = UserDefaults(suiteName: "group.com.taaafi.app")
        let events = defaults?.array(forKey: "fortMonitorEvents") ?? []
        if let data = try? JSONSerialization.data(withJSONObject: events),
           let str = String(data: data, encoding: .utf8) {
            logger.info("iOS→Dart: returning \(events.count) monitor events")
            result(str)
        } else {
            result("[]")
        }
    }
}
