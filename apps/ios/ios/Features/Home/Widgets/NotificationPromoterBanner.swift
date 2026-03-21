//
//  NotificationPromoterBanner.swift
//  ios
//

import SwiftUI
import UserNotifications

struct NotificationPromoterBanner: View {
    let isAuthorized: Bool

    var body: some View {
        if !isAuthorized {
            Button {
                HapticService.lightImpact()
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.success700)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "home.notification.enableTitle"))
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.success800)

                        Text(String(localized: "home.notification.enableSubtitle"))
                            .font(Typography.small)
                            .foregroundStyle(AppColors.success600)
                    }

                    Spacer()

                    Image(systemName: AppIcon.chevronForward.systemName)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.success400)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.success50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.success200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.md)
        }
    }
}

#Preview {
    NotificationPromoterBanner(isAuthorized: false)
}
