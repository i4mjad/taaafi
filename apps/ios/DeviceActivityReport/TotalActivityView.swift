//
//  TotalActivityView.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI
import os

// #region agent log
private let dbg = Logger(subsystem: "com.taaafi.debug", category: "86f59f")
// #endregion

struct TotalActivityView: View {
    let report: ActivityReport

    private var threats: [AppDetail] { report.apps.filter { $0.classification == .threat } }
    private var safes: [AppDetail] { report.apps.filter { $0.classification == .safe } }
    private var neutrals: [AppDetail] { report.apps.filter { $0.classification == .neutral } }

    var body: some View {
        List {
            Section {
                Text(formatDuration(report.totalDuration))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)

                HStack(spacing: 8) {
                    StatCard(icon: "shield.fill", value: "\(report.guardScore)%", label: "guard", color: scoreColor)
                    StatCard(icon: "iphone.and.arrow.forward", value: "\(report.totalPickups)", label: "pickups", color: .secondary)
                    StatCard(icon: "bell.fill", value: "\(report.totalNotifications)", label: "notifs", color: .secondary)
                }
                .listRowSeparator(.hidden)
            }

            if !threats.isEmpty {
                Section(header: Label("Threats (\(threats.count))", systemImage: "exclamationmark.shield").foregroundStyle(.red)) {
                    ForEach(threats) { app in
                        AppRow(app: app, color: .red, maxDuration: report.apps.first?.duration ?? 1)
                    }
                }
            }

            if !safes.isEmpty {
                Section(header: Label("Safe (\(safes.count))", systemImage: "checkmark.shield").foregroundStyle(.green)) {
                    ForEach(safes) { app in
                        AppRow(app: app, color: .green, maxDuration: report.apps.first?.duration ?? 1)
                    }
                }
            }

            if !neutrals.isEmpty {
                Section(header: Label("Other (\(neutrals.count))", systemImage: "shield").foregroundStyle(.gray)) {
                    ForEach(neutrals) { app in
                        AppRow(app: app, color: .gray, maxDuration: report.apps.first?.duration ?? 1)
                    }
                }
            }

            // #region agent log
            if !report.debugInfo.isEmpty {
                Section {
                    Text(report.debugInfo)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            // #endregion
        }
        .listStyle(.insetGrouped)
        // #region agent log
        .onAppear {
            dbg.notice("[H4] view_onAppear totalDur=\(report.totalDuration, privacy: .public) apps=\(report.apps.count, privacy: .public) score=\(report.guardScore, privacy: .public)")
        }
        // #endregion
    }

    private var scoreColor: Color {
        if report.guardScore >= 70 { return .green }
        if report.guardScore >= 40 { return .orange }
        return .red
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - App Row

private struct AppRow: View {
    let app: AppDetail
    let color: Color
    let maxDuration: TimeInterval

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline)
                Text(app.categoryName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(formatDuration(app.duration))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Hourly Bar Chart

private struct HourlyBarChart: View {
    let hourlyData: [HourlyUsage]

    private var maxHourDuration: TimeInterval {
        hourlyData.map { $0.safeDuration + $0.threatDuration }.max() ?? 1
    }

    private var visibleHours: [HourlyUsage] {
        hourlyData.filter { $0.hour >= 6 && $0.hour <= 23 }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Safe").font(.caption2).foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("Threat").font(.caption2).foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(visibleHours) { hour in
                    HStack(alignment: .bottom, spacing: 1) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.green)
                            .frame(height: barHeight(hour.safeDuration))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.red)
                            .frame(height: barHeight(hour.threatDuration))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)

            HStack(spacing: 0) {
                ForEach(visibleHours) { hour in
                    Text(hour.hour % 3 == 0 ? "\(hour.hour)" : "")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func barHeight(_ duration: TimeInterval) -> CGFloat {
        guard maxHourDuration > 0 else { return 0 }
        return max(0, CGFloat(duration / maxHourDuration) * 90)
    }
}

#Preview {
    TotalActivityView(report: ActivityReport(
        totalDuration: 22620,
        totalPickups: 42,
        totalNotifications: 89,
        apps: [
            AppDetail(name: "Instagram", categoryName: "Social Networking", duration: 6300, pickups: 15, notifications: 30, classification: .threat),
            AppDetail(name: "YouTube", categoryName: "Entertainment", duration: 4320, pickups: 5, notifications: 8, classification: .threat),
            AppDetail(name: "Twitter", categoryName: "Social Networking", duration: 3120, pickups: 8, notifications: 12, classification: .threat),
            AppDetail(name: "Notes", categoryName: "Productivity", duration: 1800, pickups: 3, notifications: 0, classification: .safe),
            AppDetail(name: "WhatsApp", categoryName: "Social Networking", duration: 1500, pickups: 10, notifications: 25, classification: .threat),
            AppDetail(name: "Netflix", categoryName: "Entertainment", duration: 1080, pickups: 2, notifications: 3, classification: .threat),
            AppDetail(name: "Safari", categoryName: "Productivity", duration: 900, pickups: 4, notifications: 1, classification: .safe)
        ],
        guardScore: 14,
        safeDuration: 2700,
        threatDuration: 16320,
        hourlyBreakdown: (0...23).map { h in
            HourlyUsage(
                id: h, hour: h,
                safeDuration: h >= 9 && h <= 17 ? Double.random(in: 60...600) : 0,
                threatDuration: h >= 8 && h <= 22 ? Double.random(in: 120...900) : 0
            )
        }
    ))
}
