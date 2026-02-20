//
//  GuardScreen.swift
//  ios
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI
import FamilyControls
import DeviceActivity

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct GuardScreen: View {
    @Environment(ScreenTimeManager.self) private var screenTimeManager
    @State private var selectedDate = Date.now
    @State private var reportID = UUID()

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        NavigationStack {
            Group {
                if screenTimeManager.authorizationStatus == .approved {
                    authorizedView
                } else {
                    permissionView
                }
            }
            .navigationTitle("Guard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: GuardSettingsScreen()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    // MARK: - Authorized

    private var authorizedView: some View {
        ScrollView {
            VStack(spacing: 0) {
                dateToolbar
                    .padding(.bottom, 16)

                DeviceActivityReport(
                    .totalActivity,
                    filter: DeviceActivityFilter(
                        segment: .hourly(
                            during: DateInterval(
                                start: Calendar.current.startOfDay(for: selectedDate),
                                end: isToday ? .now : startOfNextDay(selectedDate)
                            )
                        )
                    )
                )
                .id(reportID)
                .frame(height: 1500)
                .task {
                    // Workaround: extension can render blank on first load,
                    // force a re-render after a short delay
                    try? await Task.sleep(for: .milliseconds(500))
                    reportID = UUID()
                }
            }
            .padding()
        }
    }

    // MARK: - Date Toolbar

    private var dateToolbar: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
            }

            Spacer()

            Text(dateLabelText)
                .font(.headline)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
            }
            .disabled(isToday)
        }
        .padding(.horizontal, 8)
    }

    private var dateLabelText: String {
        if isToday {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private func startOfNextDay(_ date: Date) -> Date {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
    }

    // MARK: - Permission Request

    private var permissionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("Screen Time Permission")
                .font(.title2.bold())

            Text("Grant Screen Time access so Guard can show your daily usage and help you stay on track.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await screenTimeManager.requestAuthorization()
                    if screenTimeManager.authorizationStatus == .approved {
                        screenTimeManager.startMonitoring()
                    }
                }
            } label: {
                Text("Enable Screen Time Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}
