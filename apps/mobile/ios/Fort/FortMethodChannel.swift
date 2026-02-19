import Flutter
import UIKit
import FamilyControls
import DeviceActivity
import os.log

private let logger = Logger(subsystem: "com.taaafi.fort", category: "FortMethodChannel")

/// Main MethodChannel handler for the Fort feature on iOS.
/// Bridges Flutter <-> Screen Time API (FamilyControls framework).
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
        default:
            logger.warning("iOS→Dart: \(call.method) NOT_IMPLEMENTED")
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FamilyControls Auth

    private func checkFamilyControlsAuth(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            logger.info("iOS→Dart: checkAuth status=\(String(describing: status))")
            result(status == .approved)
        } else {
            logger.warning("iOS→Dart: checkAuth iOS<16, returning false")
            result(false)
        }
    }

    private func requestFamilyControlsAuth(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            logger.info("iOS: requesting FamilyControls auth...")
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let status = AuthorizationCenter.shared.authorizationStatus
                    logger.info("iOS→Dart: requestAuth status=\(String(describing: status))")
                    result(status == .approved)
                } catch {
                    logger.error("iOS→Dart: requestAuth ERROR: \(error.localizedDescription)")
                    result(false)
                }
            }
        } else {
            logger.warning("iOS→Dart: requestAuth iOS<16, returning false")
            result(false)
        }
    }

    // MARK: - Usage Report

    /// Reads category-level usage from the app group shared UserDefaults.
    /// Data is written by the DeviceActivityReportExtension (the only place
    /// on iOS with access to actual usage data).
    private func getUsageReport(result: @escaping FlutterResult) {
        let suiteName = "group.com.taaafi.app"
        let key = "fortUsageReport"
        logger.info("iOS: reading UserDefaults suiteName=\(suiteName) key=\(key)")

        let defaults = UserDefaults(suiteName: suiteName)
        if defaults == nil {
            logger.error("iOS: UserDefaults(suiteName: \(suiteName)) returned nil — app group not configured?")
        }

        // Log all keys in the suite for debugging
        let allKeys = defaults?.dictionaryRepresentation().keys.joined(separator: ", ") ?? "none"
        logger.info("iOS: UserDefaults keys in suite: \(allKeys)")

        guard let jsonString = defaults?.string(forKey: key) else {
            logger.warning("iOS→Dart: no data at key '\(key)' — DeviceActivityReportExtension hasn't written yet")
            // Return empty summary
            let empty: [String: Any] = [
                "categories": [] as [[String: Any]],
                "totalScreenTimeMinutes": 0,
                "pickups": 0,
                "date": ISO8601DateFormatter().string(from: Date())
            ]
            if let data = try? JSONSerialization.data(withJSONObject: empty),
               let str = String(data: data, encoding: .utf8) {
                logger.info("iOS→Dart: returning empty summary")
                result(str)
            } else {
                result(nil)
            }
            return
        }

        logger.info("iOS→Dart: found usage data, length=\(jsonString.count)")
        logger.info("iOS→Dart: data=\(jsonString)")
        result(jsonString)
    }
}
