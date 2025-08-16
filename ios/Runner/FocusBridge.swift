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
        let center = AuthorizationCenter.shared
        let currentStatus = await center.authorizationStatus
        FocusLogger.d("requestAuthorization current status: \(currentStatus)")
        
        if currentStatus != .approved {
            FocusLogger.d("requesting authorization for individual")
            try await center.requestAuthorization(for: .individual)
            let newStatus = await center.authorizationStatus
            FocusLogger.d("authorization result: \(newStatus)")
        } else {
            FocusLogger.d("authorization already approved")
        }
    }

    // 2) Present the FamilyActivityPicker modally
    func presentPicker() {
        FocusLogger.d("presenting FamilyActivityPicker")
        let vc = UIHostingController(rootView: FamilyPickerView())
        vc.modalPresentationStyle = .formSheet
        UIApplication.shared.topMostViewController()?.present(vc, animated: true)
        FocusLogger.d("FamilyActivityPicker presented")
    }

    // 3) Start an hourly DeviceActivity monitor (context name: everyHour)
    func startHourlyMonitoring() throws {
        FocusLogger.d("startHourlyMonitoring")
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(minute: 0),
            intervalEnd:   DateComponents(minute: 59),
            repeats: true
        )
        try DeviceActivityCenter().startMonitoring(.everyHour, during: schedule)
        FocusLogger.d("hourly monitoring started")
    }

    // 4) Read last snapshot from App Group
    func getLastSnapshot() -> [String: Any] {
        let ud = UserDefaults(suiteName: FocusShared.appGroupId)
        let snapshot = ud?.dictionary(forKey: FocusShared.lastSnapshotKey) ?? [:]
        FocusLogger.d("getLastSnapshot retrieved", snapshot)
        return snapshot
    }
}

