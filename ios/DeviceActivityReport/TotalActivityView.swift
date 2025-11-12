//
//  TotalActivityView.swift
//  DeviceActivityReport
//
//  SwiftUI view displaying Screen Time data
//

import SwiftUI

/// Simple view that displays total activity time
/// Receives formatted string from TotalActivityReport.makeConfiguration
struct TotalActivityView: View {
    /// Formatted time string (e.g., "3h 45m")
    let totalActivity: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            // Title
            Text("Today's Screen Time")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Total time
        Text(totalActivity)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Preview for development
#Preview {
    TotalActivityView(totalActivity: "3h 45m")
}
