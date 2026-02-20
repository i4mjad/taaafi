//
//  ActivityReport.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import Foundation

struct ActivityReport {
    let totalDuration: TimeInterval
    let totalPickups: Int
    let totalNotifications: Int
    let categories: [CategoryUsage]
}

struct CategoryUsage: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let apps: [AppUsage]
}

struct AppUsage: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let pickups: Int
    let notifications: Int
}
