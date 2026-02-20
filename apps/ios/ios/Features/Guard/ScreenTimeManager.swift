//
//  ScreenTimeManager.swift
//  ios
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import FamilyControls
import DeviceActivity
import Foundation

@Observable
class ScreenTimeManager {
    var authorizationStatus: AuthorizationStatus = .notDetermined
    var isLoading = true

    init() {
        let status = AuthorizationCenter.shared.authorizationStatus
        authorizationStatus = status
        if status == .approved {
            isLoading = false
            startMonitoring()
        } else {
            // Status can return .notDetermined briefly on cold launch
            // even if already authorized — re-check after a short delay
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                authorizationStatus = AuthorizationCenter.shared.authorizationStatus
                if authorizationStatus == .approved {
                    startMonitoring()
                }
                isLoading = false
            }
        }
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            print("ScreenTimeManager: authorization failed — \(error.localizedDescription)")
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        }
    }

    func startMonitoring() {
        let center = DeviceActivityCenter()

        // Daily schedule: midnight to midnight
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        // Threshold events at key minute marks
        let thresholdMinutes = [1, 5, 15, 30, 60, 120, 180, 240, 360]
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in thresholdMinutes {
            let name = DeviceActivityEvent.Name("threshold_\(minutes)m")
            events[name] = DeviceActivityEvent(
                threshold: DateComponents(minute: minutes)
            )
        }

        do {
            try center.startMonitoring(
                .daily,
                during: schedule,
                events: events
            )
        } catch {
            print("ScreenTimeManager: failed to start monitoring — \(error.localizedDescription)")
        }
    }
}

extension DeviceActivityName {
    static let daily = Self("daily")
}
