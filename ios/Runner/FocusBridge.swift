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
        if await center.authorizationStatus != .approved {
            try await center.requestAuthorization(for: .individual)
        }
    }

    // 2) Present the FamilyActivityPicker modally
    func presentPicker() {
        let vc = UIHostingController(rootView: FamilyPickerView())
        vc.modalPresentationStyle = .formSheet
        UIApplication.shared.topMostViewController()?.present(vc, animated: true)
    }

    // 3) Start an hourly DeviceActivity monitor (context name: everyHour)
    func startHourlyMonitoring() throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(minute: 0),
            intervalEnd:   DateComponents(minute: 59),
            repeats: true
        )
        try DeviceActivityCenter().startMonitoring(.everyHour, during: schedule)
    }

    // 4) Read last snapshot from App Group
    func getLastSnapshot() -> [String: Any] {
        let ud = UserDefaults(suiteName: FocusShared.appGroupId)
        return ud?.dictionary(forKey: FocusShared.lastSnapshotKey) ?? [:]
    }
}

