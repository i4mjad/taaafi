//
//  HomeViewModel.swift
//  ios
//

import Foundation
import UserNotifications

@Observable
@MainActor
final class HomeViewModel {
    var notificationCount = MockHomeData.notificationCount
    var warningCount = MockHomeData.warningCount
    var isNotificationPermissionGranted = false

    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isNotificationPermissionGranted = settings.authorizationStatus == .authorized
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isNotificationPermissionGranted = granted
        } catch {
            print("[HomeViewModel] Notification permission error: \(error)")
        }
    }
}
