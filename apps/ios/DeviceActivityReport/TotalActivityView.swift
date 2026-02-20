//
//  TotalActivityView.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI

struct TotalActivityView: View {
    let report: ActivityReport

    var body: some View {
        VStack(spacing: 20) {
            // Total screen time
            Text(formatDuration(report.totalDuration))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .padding(.top, 8)

            // Guard Score + Pickups + Notifications
            HStack(spacing: 8) {
                StatCard(
                    icon: "shield.fill",
                    value: "\(report.guardScore)%",
                    label: "guard",
                    color: scoreColor
                )
                StatCard(
                    icon: "iphone.and.arrow.forward",
                    value: "\(report.totalPickups)",
                    label: "pickups",
                    color: .secondary
                )
                StatCard(
                    icon: "bell.fill",
                    value: "\(report.totalNotifications)",
                    label: "notifs",
                    color: .secondary
                )
            }

            // Hourly bar chart
            HourlyBarChart(hourlyData: report.hourlyBreakdown)

            Divider()

            // Categories grouped by classification: threats, safe, neutral
            let threats = report.categories.filter { $0.classification == .threat }
            let safes = report.categories.filter { $0.classification == .safe }
            let neutrals = report.categories.filter { $0.classification == .neutral }

            ForEach(threats) { category in
                CategoryRow(category: category, maxDuration: report.categories.first?.duration ?? 1)
            }
            ForEach(safes) { category in
                CategoryRow(category: category, maxDuration: report.categories.first?.duration ?? 1)
            }
            ForEach(neutrals) { category in
                CategoryRow(category: category, maxDuration: report.categories.first?.duration ?? 1)
            }

            Spacer(minLength: 0)
        }
        .padding()
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
            // Legend
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

            // Bars
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(visibleHours) { hour in
                    HStack(alignment: .bottom, spacing: 1) {
                        // Safe bar (green)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.green)
                            .frame(height: barHeight(hour.safeDuration))
                        // Threat bar (red)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.red)
                            .frame(height: barHeight(hour.threatDuration))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)

            // Hour labels
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

// MARK: - Category Row

private struct CategoryRow: View {
    let category: CategoryUsage
    let maxDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(classColor)
                    .frame(width: 10, height: 10)

                Text(category.name)
                    .font(.subheadline.bold())

                Spacer()

                Text(formatDuration(category.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Duration bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(classColor.opacity(0.3))
                    .frame(
                        width: geo.size.width * CGFloat(category.duration / maxDuration),
                        height: 6
                    )
            }
            .frame(height: 6)

            // Top apps
            ForEach(category.apps) { app in
                HStack {
                    Text(app.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)
                    Spacer()
                    Text(formatDuration(app.duration))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var classColor: Color {
        switch category.classification {
        case .safe: return .green
        case .threat: return .red
        case .neutral: return .gray
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

#Preview {
    TotalActivityView(report: ActivityReport(
        totalDuration: 22620,
        totalPickups: 42,
        totalNotifications: 89,
        categories: [
            CategoryUsage(name: "Social Networking", duration: 10920, apps: [
                AppUsage(name: "Instagram", duration: 6300, pickups: 15, notifications: 30),
                AppUsage(name: "Twitter", duration: 3120, pickups: 8, notifications: 12),
                AppUsage(name: "WhatsApp", duration: 1500, pickups: 10, notifications: 25)
            ], classification: .threat),
            CategoryUsage(name: "Entertainment", duration: 5400, apps: [
                AppUsage(name: "YouTube", duration: 4320, pickups: 5, notifications: 8),
                AppUsage(name: "Netflix", duration: 1080, pickups: 2, notifications: 3)
            ], classification: .threat),
            CategoryUsage(name: "Productivity", duration: 2700, apps: [
                AppUsage(name: "Notes", duration: 1800, pickups: 3, notifications: 0),
                AppUsage(name: "Safari", duration: 900, pickups: 4, notifications: 1)
            ], classification: .safe)
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
