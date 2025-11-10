//
//  FocusBridge.swift
//  Runner
//
//  Created by Amjad Khalfan on 15/08/2025.
//

import Foundation
import FamilyControls
import DeviceActivity
import SwiftUI

@MainActor
final class FocusBridge {
    static let shared = FocusBridge()
    private init() {}

    // 1) Request FamilyControls authorization
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
    
    private func statusToString(_ status: AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .approved: return "approved"
        @unknown default: return "unknown"
        }
    }

    // 2) Present the FamilyActivityPicker modally
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

    // 3) Start DeviceActivity monitoring (all-day schedule per Apple requirements)
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

    // 4) Read last snapshot from App Group
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

