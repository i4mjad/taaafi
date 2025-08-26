// //
// //  FocusBridge.swift
// //  Runner
// //
// //  Created by Amjad Khalfan on 15/08/2025.
// //

// import Foundation
// import FamilyControls
// import DeviceActivity
// import SwiftUI

// @MainActor
// final class FocusBridge {
//     static let shared = FocusBridge()
//     private init() {}

//     // 1) Request FamilyControls authorization
//     func requestAuthorization() async throws {
//         let center = AuthorizationCenter.shared
//         let currentStatus = await center.authorizationStatus
//         FocusLogger.d("requestAuthorization current status: \(currentStatus)")
        
//         if currentStatus != .approved {
//             FocusLogger.d("requesting authorization for individual")
//             try await center.requestAuthorization(for: .individual)
//             let newStatus = await center.authorizationStatus
//             FocusLogger.d("authorization result: \(newStatus)")
//         } else {
//             FocusLogger.d("authorization already approved")
//         }
//     }

//     // 2) Present the FamilyActivityPicker modally
//     func presentPicker() {
//         FocusLogger.d("presenting FamilyActivityPicker")
//         let vc = UIHostingController(rootView: FamilyPickerView())
//         vc.modalPresentationStyle = .formSheet
//         UIApplication.shared.topMostViewController()?.present(vc, animated: true)
//         FocusLogger.d("FamilyActivityPicker presented")
//     }

//     // 3) Start frequent DeviceActivity monitoring (every 5 minutes + events)
//     // DISABLED: Extension not built in CI/CD
//     func startHourlyMonitoring() throws {
//         FocusLogger.d("DeviceActivity monitoring disabled - extension not available")
//         return
//         /*
//         FocusLogger.d("startRealtimeMonitoring")
        
//         // 5-minute intervals for regular updates
//         let frequentSchedule = DeviceActivitySchedule(
//             intervalStart: DateComponents(minute: 0),
//             intervalEnd: DateComponents(minute: 4, second: 59),
//             repeats: true
//         )
        
//         // Set up usage threshold events for real-time notifications
//         let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
//             .usageThreshold: DeviceActivityEvent(
//                 applications: FocusSelectionStore.load()?.applicationTokens ?? Set(),
//                 threshold: DateComponents(minute: 1) // Trigger every 1 minute of usage
//             )
//         ]
        
//         try DeviceActivityCenter().startMonitoring(
//             .realtimeUpdates, 
//             during: frequentSchedule,
//             events: events
//         )
//         FocusLogger.d("realtime monitoring started (5min intervals + 1min thresholds)")
//         */
//     }

//     // 4) Read last snapshot from App Group
//     func getLastSnapshot() -> [String: Any] {
//         let ud = UserDefaults(suiteName: FocusShared.appGroupId)
//         let snapshot = ud?.dictionary(forKey: FocusShared.lastSnapshotKey) ?? [:]
//         FocusLogger.d("getLastSnapshot retrieved", snapshot)
//         return snapshot
//     }
// }

