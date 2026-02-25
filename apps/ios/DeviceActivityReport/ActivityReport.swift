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
    let apps: [AppDetail]
    let guardScore: Int
    let safeDuration: TimeInterval
    let threatDuration: TimeInterval
    let hourlyBreakdown: [HourlyUsage]
}

struct HourlyUsage: Identifiable {
    let id: Int
    let hour: Int
    let safeDuration: TimeInterval
    let threatDuration: TimeInterval
}

struct AppDetail: Identifiable {
    var id: String { name }
    let name: String
    let categoryName: String
    let duration: TimeInterval
    let pickups: Int
    let notifications: Int
    let classification: CategoryClass
}
