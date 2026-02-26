//
//  QuickActionsWidget.swift
//  ios
//

import SwiftUI

struct QuickActionsWidget: View {
    @Environment(ToastManager.self) private var toastManager

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "home.quickActions"))
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey800)
                .padding(.horizontal, Spacing.md)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                actionCard(
                    icon: "calendar",
                    label: String(localized: "home.action.followUp")
                )
                actionCard(
                    icon: "book",
                    label: String(localized: "home.action.addDiary")
                )
                actionCard(
                    icon: "magnifyingglass",
                    label: String(localized: "home.action.exploreContent")
                )
                actionCard(
                    icon: "chart.bar",
                    label: String(localized: "home.action.statistics")
                )
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private func actionCard(icon: String, label: String) -> some View {
        Button {
            HapticService.lightImpact()
            toastManager.show(.info, message: String(localized: "home.comingSoon"))
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.primary)

                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey700)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(AppColors.primary50)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.primary100, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickActionsWidget()
        .environment(ToastManager())
}
