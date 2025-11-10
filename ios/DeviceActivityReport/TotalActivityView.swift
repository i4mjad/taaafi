//
//  TotalActivityView.swift
//  DeviceActivityReport
//
//  SwiftUI view that displays processed Screen Time usage data
//

import SwiftUI
import FamilyControls

/// Main view that displays total activity report
/// Receives processed configuration data and renders beautiful UI
struct TotalActivityView: View {
    /// Configuration containing all formatted usage data
    let config: ActivityReportConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Total Screen Time Header
            // Displays the cumulative screen time for the day in a prominent card
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Screen Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(config.totalScreenTime)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // MARK: - Apps List Section
            // Shows either the list of apps or an empty state
            if config.apps.isEmpty {
                // Empty state when no usage data is available
                VStack(spacing: 8) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No app usage data yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Use some apps and check back later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // List of apps with usage stats
                VStack(alignment: .leading, spacing: 0) {
                    Text("Top Apps")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    // Display each app in a row
                    ForEach(config.apps) { app in
                        AppUsageRow(app: app)
                        
                        // Add divider between apps (but not after the last one)
                        if app.id != config.apps.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - App Usage Row Component

/// Individual row displaying one app's usage information
/// Shows app icon placeholder, name, and duration
struct AppUsageRow: View {
    /// The app data to display
    let app: AppUsageData
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - App Icon
            // Since we can't access actual app icons in extension, show placeholder
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "app.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }
            
            // MARK: - App Name
            Text(app.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            // MARK: - Duration
            // Displays formatted time (e.g., "1h 30m")
            Text(app.durationFormatted)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

/// Preview provider for development/testing
/// Shows sample data to visualize the UI during development
#Preview {
    TotalActivityView(config: ActivityReportConfig(
        apps: [
            AppUsageData(
                name: "Instagram",
                bundle: "com.burbn.instagram",
                duration: 5400,
                durationFormatted: "1h 30m"
            ),
            AppUsageData(
                name: "TikTok",
                bundle: "com.zhiliaoapp.musically",
                duration: 3600,
                durationFormatted: "1h"
            ),
            AppUsageData(
                name: "Twitter",
                bundle: "com.twitter.twitter",
                duration: 1800,
                durationFormatted: "30m"
            )
        ],
        totalScreenTime: "3h",
        date: Date()
    ))
}
