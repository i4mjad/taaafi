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

            // Pickups & Notifications
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(report.totalPickups)")
                        .font(.subheadline.bold())
                    Text("pickups")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary)
                .clipShape(Capsule())

                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(report.totalNotifications)")
                        .font(.subheadline.bold())
                    Text("notifications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary)
                .clipShape(Capsule())
            }

            Divider()

            // Category breakdown
            ForEach(report.categories) { category in
                CategoryRow(
                    category: category,
                    maxDuration: report.categories.first?.duration ?? 1
                )
            }

            Spacer(minLength: 0)
        }
        .padding()
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

// MARK: - Category Row

private struct CategoryRow: View {
    let category: CategoryUsage
    let maxDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category header
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(colorForCategory(category.name))
                    .frame(width: 4, height: 20)

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
                    .fill(colorForCategory(category.name).opacity(0.3))
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
                        .padding(.leading, 16)
                    Spacer()
                    Text(formatDuration(app.duration))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
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

    private func colorForCategory(_ name: String) -> Color {
        switch name {
        case "Social Networking": return .blue
        case "Entertainment": return .purple
        case "Productivity": return .green
        case "Games": return .orange
        case "Education": return .cyan
        case "Information & Reading": return .yellow
        case "Health & Fitness": return .pink
        case "Creativity": return .orange
        default: return .gray
        }
    }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
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
            ]),
            CategoryUsage(name: "Entertainment", duration: 5400, apps: [
                AppUsage(name: "YouTube", duration: 4320, pickups: 5, notifications: 8),
                AppUsage(name: "Netflix", duration: 1080, pickups: 2, notifications: 3)
            ]),
            CategoryUsage(name: "Productivity", duration: 2700, apps: [
                AppUsage(name: "Notes", duration: 1800, pickups: 3, notifications: 0),
                AppUsage(name: "Safari", duration: 900, pickups: 4, notifications: 1)
            ])
        ]
    ))
}
