//
//  FocusBridge.swift
//  Runner
//
//  Bridge between Flutter and iOS Family Controls / DeviceActivity APIs
//  Provides four main functions:
//  1. Request Family Controls authorization from user
//  2. Present app/category picker for user selection
//  3. Start DeviceActivity monitoring with schedules and threshold events
//  4. Retrieve usage snapshot data from App Group shared storage
//
//  All methods are marked @MainActor as Family Controls APIs require main thread
//  Created by Amjad Khalfan on 15/08/2025.
//

import Foundation
import FamilyControls
import DeviceActivity
import SwiftUI

/// Singleton bridge class providing Family Controls functionality to Flutter
/// @MainActor ensures all methods run on main thread (required by Family Controls)
@MainActor
final class FocusBridge {
    /// Shared singleton instance
    static let shared = FocusBridge()
    
    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Authorization
    
    /// Requests Family Controls authorization from the user
    /// Shows system permission dialog if not already approved
    /// Required before using FamilyActivityPicker or DeviceActivity monitoring
    ///
    /// - Throws: Authorization error if user denies or if request fails
    /// - Note: Authorization status persists across app launches
    func requestAuthorization() async throws {
        FocusLogger.d("=== requestAuthorization: START ===")
        let center = AuthorizationCenter.shared
        let currentStatus = await center.authorizationStatus
        FocusLogger.d("requestAuthorization: current status = \(currentStatus.rawValue) [\(statusToString(currentStatus))]")
        
        if currentStatus != .approved {
            FocusLogger.d("requestAuthorization: status NOT approved, requesting for .individual")
            do {
                try await center.requestAuthorization(for: .individual)
                let newStatus = await center.authorizationStatus
                FocusLogger.d("requestAuthorization: ✅ request completed, new status = \(newStatus.rawValue) [\(statusToString(newStatus))]")
            } catch {
                FocusLogger.e("requestAuthorization: ❌ ERROR - \(error.localizedDescription)")
                throw error
            }
        } else {
            FocusLogger.d("requestAuthorization: ✅ already approved, skipping request")
        }
        FocusLogger.d("=== requestAuthorization: END ===")
    }
    
    /// Converts AuthorizationStatus enum to human-readable string for logging
    /// - Parameter status: The authorization status to convert
    /// - Returns: String representation ("notDetermined", "denied", "approved", or "unknown")
    private func statusToString(_ status: AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .approved: return "approved"
        @unknown default: return "unknown"
        }
    }

    // MARK: - App Selection
    
    /// Presents the FamilyActivityPicker modal for user to select apps/categories
    /// The picker allows users to choose which apps and categories to monitor
    /// Selection is automatically saved via FocusSelectionStore when user makes changes
    ///
    /// - Important: Requires Family Controls authorization to be approved first
    /// - Note: Picker is presented on the topmost view controller
    func presentPicker() {
        FocusLogger.d("=== presentPicker: START ===")
        FocusLogger.d("presentPicker: creating FamilyPickerView")
        let vc = UIHostingController(rootView: FamilyPickerView())
        vc.modalPresentationStyle = .formSheet
        
        guard let topVC = UIApplication.shared.topMostViewController() else {
            FocusLogger.e("presentPicker: ❌ ERROR - no top view controller found")
            return
        }
        
        FocusLogger.d("presentPicker: presenting picker on \(type(of: topVC))")
        topVC.present(vc, animated: true)
        FocusLogger.d("presentPicker: ✅ picker presented successfully")
        FocusLogger.d("=== presentPicker: END ===")
    }

    // MARK: - Monitoring
    
    /// Starts DeviceActivity monitoring with all-day schedule and threshold events
    /// 
    /// Monitoring Strategy:
    /// - Schedule: All-day (00:00 to 23:59) repeating daily
    /// - Threshold Events: Triggered every 15 minutes of app usage
    /// - Monitor Extension: Receives callbacks and updates usage data
    ///
    /// Apple Requirements:
    /// - Minimum interval: 15 minutes (we use full day to satisfy this)
    /// - Must specify apps/categories to monitor (loaded from FocusSelectionStore)
    /// - Extension runs in separate process with limited resources
    ///
    /// - Throws: DeviceActivity error if schedule is invalid or monitoring fails
    /// - Note: Monitoring continues even when app is closed/in background
    func startHourlyMonitoring() throws {
        FocusLogger.d("=== startHourlyMonitoring: START ===")
        
        // Load selected apps
        let selection = FocusSelectionStore.load()
        let appCount = selection?.applicationTokens.count ?? 0
        let categoryCount = selection?.categoryTokens.count ?? 0
        FocusLogger.d("startHourlyMonitoring: loaded selection - apps=\(appCount), categories=\(categoryCount)")
        
        if appCount == 0 && categoryCount == 0 {
            FocusLogger.d("startHourlyMonitoring: ⚠️ WARNING - no apps or categories selected, monitoring will not track anything")
        }
        
        // Monitor for entire day (midnight to midnight)
        // Apple requires monitoring window to be at least 15 minutes
        // We use full day and rely on threshold events for more frequent updates
        let allDaySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        FocusLogger.d("startHourlyMonitoring: schedule configured - start=00:00, end=23:59, repeats=true")
        
        // Set up usage threshold events for frequent updates
        // These will trigger throughout the day as users use apps
        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            .usageThreshold: DeviceActivityEvent(
                applications: selection?.applicationTokens ?? Set(),
                threshold: DateComponents(minute: 15) // Trigger every 15 minutes of usage
            )
        ]
        FocusLogger.d("startHourlyMonitoring: threshold events configured - threshold=15min")
        
        do {
            FocusLogger.d("startHourlyMonitoring: calling DeviceActivityCenter.startMonitoring(...)")
            try DeviceActivityCenter().startMonitoring(
                .realtimeUpdates, 
                during: allDaySchedule,
                events: events
            )
            FocusLogger.d("startHourlyMonitoring: ✅ monitoring started successfully")
        } catch {
            FocusLogger.e("startHourlyMonitoring: ❌ ERROR - \(error.localizedDescription)")
            throw error
        }
        
        FocusLogger.d("=== startHourlyMonitoring: END ===")
    }

    // MARK: - Data Retrieval
    
    /// Retrieves the latest usage snapshot from App Group shared storage
    /// 
    /// The snapshot is written by the Monitor extension (FocusDeviceActivityMonitor)
    /// when monitoring intervals complete or threshold events fire.
    ///
    /// Snapshot Structure:
    /// - apps: Array of app usage data [bundle, label, minutes]
    /// - domains: Web domain usage (currently unused)
    /// - pickups: Device pickup count (currently unused)
    /// - notifications: Notification count (currently unused)
    /// - generatedAt: Unix timestamp of last update
    /// - updateReason: Why snapshot was generated (intervalStart/End, thresholdReached)
    /// - lastUpdate: ISO8601 timestamp string
    ///
    /// - Returns: Dictionary containing usage snapshot, or empty dict if no data
    /// - Note: Returns empty dictionary if App Group access fails
    func getLastSnapshot() -> [String: Any] {
        FocusLogger.d("=== getLastSnapshot: START ===")
        
        guard let ud = UserDefaults(suiteName: FocusShared.appGroupId) else {
            FocusLogger.e("getLastSnapshot: ❌ ERROR - could not access app group '\(FocusShared.appGroupId)'")
            return [:]
        }
        
        FocusLogger.d("getLastSnapshot: accessing key '\(FocusShared.lastSnapshotKey)' in app group")
        let snapshot = ud.dictionary(forKey: FocusShared.lastSnapshotKey) ?? [:]
        
        if snapshot.isEmpty {
            FocusLogger.d("getLastSnapshot: ⚠️ no snapshot data found")
        } else {
            let apps = (snapshot["apps"] as? [[String: Any]])?.count ?? 0
            let generatedAt = snapshot["generatedAt"] as? Int ?? 0
            let updateReason = snapshot["updateReason"] as? String ?? "unknown"
            FocusLogger.d("getLastSnapshot: ✅ snapshot found - apps=\(apps), reason=\(updateReason), timestamp=\(generatedAt)")
        }
        
        FocusLogger.d("=== getLastSnapshot: END ===")
        return snapshot
    }
}

