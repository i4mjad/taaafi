import Flutter
import UIKit
import FamilyControls
import DeviceActivity

/// Main MethodChannel handler for the Fort feature on iOS.
/// Bridges Flutter ↔ Screen Time API (FamilyControls framework).
class FortMethodChannel: NSObject {
    static let channelName = "com.taaafi.fort"

    private let familyControlsManager = FamilyControlsManager()

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "ios_checkFamilyControlsAuth":
            checkFamilyControlsAuth(result: result)
        case "ios_requestFamilyControlsAuth":
            requestFamilyControlsAuth(result: result)
        case "ios_getUsageReport":
            getUsageReport(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FamilyControls Auth

    private func checkFamilyControlsAuth(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            result(status == .approved)
        } else {
            result(false)
        }
    }

    private func requestFamilyControlsAuth(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let status = AuthorizationCenter.shared.authorizationStatus
                    result(status == .approved)
                } catch {
                    result(false)
                }
            }
        } else {
            result(false)
        }
    }

    // MARK: - Usage Report

    /// Reads category-level usage from the app group shared UserDefaults.
    /// Data is written by the DeviceActivityReportExtension (the only place
    /// on iOS with access to actual usage data).
    private func getUsageReport(result: @escaping FlutterResult) {
        let defaults = UserDefaults(suiteName: "group.com.taaafi.app")

        guard let jsonString = defaults?.string(forKey: "fortUsageReport") else {
            // No data yet — return empty summary
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
            return
        }

        result(jsonString)
    }
}
