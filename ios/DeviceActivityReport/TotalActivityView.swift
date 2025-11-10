//
//  TotalActivityView.swift
//  DeviceActivityReport
//

import SwiftUI
import FamilyControls

struct TotalActivityView: View {
    let config: ActivityReportConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with total screen time
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
            
            // Apps list
            if config.apps.isEmpty {
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
                VStack(alignment: .leading, spacing: 0) {
                    Text("Top Apps")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    ForEach(config.apps) { app in
                        AppUsageRow(app: app)
                        
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

struct AppUsageRow: View {
    let app: AppUsageData
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "app.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }
            
            // App name
            Text(app.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Duration
            Text(app.durationFormatted)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TotalActivityView(config: ActivityReportConfig(
        apps: [
            AppUsageData(name: "Instagram", bundle: "com.burbn.instagram", duration: 5400, durationFormatted: "1h 30m"),
            AppUsageData(name: "TikTok", bundle: "com.zhiliaoapp.musically", duration: 3600, durationFormatted: "1h"),
            AppUsageData(name: "Twitter", bundle: "com.twitter.twitter", duration: 1800, durationFormatted: "30m")
        ],
        totalScreenTime: "3h",
        date: Date()
    ))
}
