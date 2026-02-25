//
//  TotalActivityView.swift
//  DeviceActivityReport
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI
import Charts

// MARK: - 4-pt Spacing System

private enum Spacing {
    static let xxs: CGFloat = 4   // tight inner (legend dots, inline gaps)
    static let xs: CGFloat = 8   // standard inner (icon-text, bar gaps)
    static let sm: CGFloat = 12 // card inner padding, section gaps
    static let md: CGFloat = 16 // standard card padding, horizontal insets
    static let lg: CGFloat = 20 // medium section spacing
    static let xl: CGFloat = 24 // section-to-section vertical
    static let xxl: CGFloat = 32 // large outer horizontal
}

// MARK: - Card Modifier

private struct CardModifier: ViewModifier {
    var isElevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(isElevated ? Color(.systemGray5) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(isElevated ? 0.2 : 0.12), radius: isElevated ? 12 : 8, x: 0, y: 4)
    }
}

private extension View {
    func cardStyle(elevated: Bool = false) -> some View {
        modifier(CardModifier(isElevated: elevated))
    }
}

// MARK: - Total Activity View

struct TotalActivityView: View {
    let report: ActivityReport
    @State private var selectedHour: Int?

    private var threats: [AppDetail] { report.apps.filter { $0.classification == .threat } }
    private var topThreats: [AppDetail] { Array(threats.prefix(4)) }
    private var top10Apps: [AppDetail] { Array(report.apps.prefix(10)) }
    private var otherAppsDuration: TimeInterval {
        report.apps.dropFirst(10).reduce(0) { $0 + $1.duration }
    }

    private var selectedHourUsage: HourlyUsage? {
        guard let h = selectedHour else { return nil }
        return report.hourlyBreakdown.first { $0.hour == h }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if let hour = selectedHour, let usage = selectedHourUsage {
                    hourDetailSection(hour: hour, usage: usage)
                } else {
                    heroSection
                    statsRowCard
                }
                hourlyChartCard
                topAppsCard
                // assistCard // Assist card hidden
                appUsageCard
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(formatDuration(report.totalDuration))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)

            Text("SCREEN TIME")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Hour Detail Section (inline, replaces hero + stats when hour selected)

    private func hourDetailSection(hour: Int, usage: HourlyUsage) -> some View {
        let total = usage.safeDuration + usage.threatDuration
        let hourScore = total > 0 ? Int((usage.safeDuration / total) * 100) : 100
        let timeRange = String(format: "%02d:00 - %02d:00", hour, hour + 1)

        return VStack(spacing: Spacing.sm) {
            VStack(spacing: Spacing.xs) {
                Text(formatDurationWithSeconds(total))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                Text("SCREEN TIME \(timeRange)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button {
                    selectedHour = nil
                } label: {
                    Text("View full day")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xxs)
            }
            .padding(.vertical, Spacing.sm)

            HStack(spacing: Spacing.xs) {
                // StatCell(label: "MOST USED", content: { MostUsedContent(apps: topApps) }) // Assets commented out
                StatCell(
                    label: "GUARD SCORE",
                    content: { Text("\(hourScore)%").font(.subheadline.bold()).foregroundStyle(scoreColor(for: hourScore)) }
                )
                StatCell(label: "PICKUPS", content: { Text("—").font(.subheadline.bold()) })
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Stats Row Card

    private var statsRowCard: some View {
        HStack(spacing: Spacing.xs) {
            // StatCell(label: "MOST USED", content: { MostUsedContent(apps: topApps) }) // Assets commented out
            StatCell(
                label: "GUARD SCORE",
                content: { Text("\(report.guardScore)%").font(.subheadline.bold()).foregroundStyle(scoreColor) }
            )
            StatCell(
                label: "PICKUPS",
                content: { Text("\(report.totalPickups)").font(.subheadline.bold()) }
            )
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Hourly Chart Card

    private var hourlyChartCard: some View {
        HourlyBarChart(
            hourlyData: report.hourlyBreakdown,
            selectedHour: $selectedHour
        )
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Top Apps Card

    private var topAppsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(top10Apps) { app in
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Circle()
                            .fill(app.classification == .threat ? Color.red : (app.classification == .safe ? Color.green : Color.gray))
                            .frame(width: 8, height: 8)
                        Text(app.name)
                            .font(.subheadline)
                        Spacer()
                        Text(formatDuration(app.duration))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text(app.categoryName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 12)
                }
            }
            if otherAppsDuration > 0 {
                HStack {
                    Text("Other")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(formatDuration(otherAppsDuration))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Assist Card (hidden)

    /*
    private var assistCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Assist")
                        .font(.headline)
                    Text("Keep distracting apps in check.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: Spacing.lg) {
                CircularGauge(
                    value: report.totalDuration > 0 ? report.threatDuration / report.totalDuration : 0,
                    centerText: formatDuration(report.threatDuration),
                    subtitle: "NO GOAL"
                )
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(topThreats) { app in
                        AssistAppRow(app: app)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.md)
        .cardStyle(elevated: true)
    }
    */

    // MARK: - App Usage Card

    private var appUsageCard: some View {
        let offlineDuration = max(0, 86400 - report.totalDuration)
        let offlinePercent = report.totalDuration > 0 ? Int((offlineDuration / 86400) * 100) : 100

        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Image(systemName: "cloud")
                    .font(.body)
                Text("Time Offline")
                    .font(.body)
                Spacer()
                Text(formatDuration(offlineDuration))
                    .font(.body)
            }
            Text("\(offlinePercent)% of your day")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private var scoreColor: Color {
        scoreColor(for: report.guardScore)
    }

    private func scoreColor(for score: Int) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }

    private func formatDurationWithSeconds(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Stat Cell

private struct StatCell<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            content()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Most Used Content

private struct MostUsedContent: View {
    let apps: [AppDetail]

    private let placeholderColors: [Color] = [
        Color(red: 0.9, green: 0.3, blue: 0.5),
        .green,
        Color(.systemGray)
    ]

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(Array(apps.enumerated()), id: \.element.id) { index, _ in
                Circle()
                    .fill(placeholderColors[safe: index] ?? .gray)
                    .frame(width: 24, height: 24)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Circular Gauge

private struct CircularGauge: View {
    let value: Double
    let centerText: String
    let subtitle: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(1, value))
                .stroke(.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: Spacing.xxs) {
                Text(centerText)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Assist App Row

private struct AssistAppRow: View {
    let app: AppDetail

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(.red)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(app.name)
                    .font(.subheadline)
                Text(formatDurationWithSeconds(app.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatDurationWithSeconds(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Usage Category (for Charts)

private enum UsageCategory: String, CaseIterable {
    case safe = "Safe"
    case danger = "Danger"
}

private struct HourlyUsageSegment: Identifiable {
    let id = UUID()
    let hour: Int
    let category: UsageCategory
    let minutes: Double
}

// MARK: - Hourly Stacked Bar Chart (Swift Charts)

private struct HourlyBarChart: View {
    let hourlyData: [HourlyUsage]
    @Binding var selectedHour: Int?

    private let domainStart = 0
    private let domainEnd = 23
    private let majorHours = [0, 6, 12, 18, 23]
    private let minutesPerHour: Double = 60

    private var chartData: [HourlyUsageSegment] {
        hourlyData
            .filter { $0.hour >= domainStart && $0.hour <= domainEnd }
            .flatMap { entry in
                let safeMinutes = entry.safeDuration / 60
                let dangerMinutes = entry.threatDuration / 60
                let idleMinutes = max(0, minutesPerHour - safeMinutes - dangerMinutes)
                let totalSafeMinutes = safeMinutes + idleMinutes
                return [
                    HourlyUsageSegment(hour: entry.hour, category: .safe, minutes: totalSafeMinutes),
                    HourlyUsageSegment(hour: entry.hour, category: .danger, minutes: dangerMinutes)
                ]
            }
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xxs) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("SAFE")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: Spacing.xxs) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("DANGER")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Chart(chartData) { entry in
                BarMark(
                    x: .value("Hour", entry.hour),
                    y: .value("Minutes", entry.minutes)
                )
                .foregroundStyle(by: .value("Category", entry.category.rawValue))
                .cornerRadius(3)
            }
            .chartForegroundStyleScale([
                UsageCategory.safe.rawValue: Color.green.opacity(0.85),
                UsageCategory.danger.rawValue: Color.red.opacity(0.85)
            ])
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = geo[proxy.plotAreaFrame]
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            let plotMinX = plotFrame.origin.x
                            let plotMaxX = plotFrame.maxX
                            let plotWidth = plotMaxX - plotMinX
                            let relativeX = location.x - plotMinX
                            let hourValue = plotWidth > 0 ? relativeX / plotWidth * Double(domainEnd - domainStart + 1) : 0
                            let hour = Int(hourValue) + domainStart
                            selectedHour = max(domainStart, min(domainEnd, hour))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: majorHours) { value in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick().foregroundStyle(.clear)
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text(String(format: "%02d", hour))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color(.systemGray).opacity(0.25))
                    AxisTick().foregroundStyle(.clear)
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXScale(domain: domainStart...domainEnd)
            .chartYScale(domain: 0...60)
            .chartLegend(.hidden)
            .frame(height: 120)
        }
    }
}

// MARK: - Preview

#Preview {
    TotalActivityView(report: ActivityReport(
        totalDuration: 21720,
        totalPickups: 107,
        totalNotifications: 89,
        apps: [
            AppDetail(name: "Instagram", categoryName: "Social Networking", duration: 5837, pickups: 15, notifications: 30, classification: .threat),
            AppDetail(name: "X", categoryName: "Social Networking", duration: 2719, pickups: 8, notifications: 12, classification: .threat),
            AppDetail(name: "LinkedIn", categoryName: "Social Networking", duration: 1276, pickups: 4, notifications: 5, classification: .threat),
            AppDetail(name: "WhatsApp", categoryName: "Social Networking", duration: 3600, pickups: 10, notifications: 25, classification: .threat),
            AppDetail(name: "Notes", categoryName: "Productivity", duration: 1800, pickups: 3, notifications: 0, classification: .safe),
            AppDetail(name: "Safari", categoryName: "Productivity", duration: 900, pickups: 4, notifications: 1, classification: .safe)
        ],
        guardScore: 75,
        safeDuration: 2700,
        threatDuration: 19020,
        hourlyBreakdown: (0...23).map { h in
            HourlyUsage(
                id: h, hour: h,
                safeDuration: h >= 9 && h <= 17 ? Double.random(in: 60...600) : 0,
                threatDuration: h >= 8 && h <= 22 ? Double.random(in: 120...900) : 0
            )
        }
    ))
}
