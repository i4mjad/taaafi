//
//  HomeScreen.swift
//  ios
//

import SwiftUI

struct HomeScreen: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    NotificationPromoterBanner(
                        isAuthorized: viewModel.isNotificationPermissionGranted
                    )

                    WarningNotificationBanner(totalWarnings: viewModel.warningCount)

                    QuickActionsWidget()

                    StreaksPreviewView()

                    CalendarPreviewView()

                    CommunityActivitySection()
                }
                .padding(.vertical, Spacing.md)
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "home.welcomeBack"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        PremiumCtaButton(isSubscribed: false)

                        notificationBell
                    }
                }
            }
            .refreshable {
                await viewModel.checkNotificationPermission()
            }
            .task {
                await viewModel.checkNotificationPermission()
            }
        }
    }

    private var notificationBell: some View {
        Button {
            toastManager.show(.info, message: String(localized: "home.comingSoon"))
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.grey700)

                if viewModel.notificationCount > 0 {
                    Text("\(viewModel.notificationCount)")
                        .font(Typography.bodyTiny)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(AppColors.error)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
        .environment(ToastManager())
}
