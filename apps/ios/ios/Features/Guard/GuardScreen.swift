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
    static let totalActivity = Self("total-activity")
}

struct GuardScreen: View {
    @Environment(ScreenTimeManager.self) private var screenTimeManager
    @State private var selectedDate = Date.now
    @State private var showDatePicker = false

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var isYesterday: Bool {
        Calendar.current.isDateInYesterday(selectedDate)
    }

    private var dateLabel: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Group {
                if screenTimeManager.isLoading {
                    ProgressView()
                } else if screenTimeManager.authorizationStatus == .approved {
                    authorizedView
                } else {
                    permissionView
                }
            }
            .navigationTitle("Guard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: GuardSettingsScreen()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDatePicker = true
                    } label: {
                        Text(dateLabel)
                            .font(Typography.footnote)
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(480)])
            }
        }
    }

    // MARK: - Authorized

    private var authorizedView: some View {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = isToday ? .now : startOfNextDay(selectedDate)

        let filter = DeviceActivityFilter(
            segment: .hourly(
                during: DateInterval(
                    start: start,
                    end: end
                )
            )
        )

        return DeviceActivityReport(.totalActivity, filter: filter)
        .onChange(of: selectedDate) {
            showDatePicker = false
        }
    }

    private func startOfNextDay(_ date: Date) -> Date {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
    }

    // MARK: - Permission Request

    private var permissionView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.primary)

            Text("Screen Time Permission")
                .font(Typography.h4)

            Text("Grant Screen Time access so Guard can show your daily usage and help you stay on track.")
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Button {
                Task {
                    await screenTimeManager.requestAuthorization()
                    if screenTimeManager.authorizationStatus == .approved {
                        screenTimeManager.startMonitoring()
                    }
                }
            } label: {
                Text("Enable Screen Time Access")
                    .font(Typography.h6)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
    }
}
