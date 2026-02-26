//
//  StreaksPreviewView.swift
//  ios
//

import SwiftUI

struct StreaksPreviewView: View {
    private let streaks = MockHomeData.streaks

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "home.streaks"))
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey800)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(streaks.enumerated()), id: \.offset) { _, streak in
                        streakCard(streak)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private func streakCard(_ streak: MockHomeData.StreakData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("\(streak.days)")
                .font(Typography.h3)
                .foregroundStyle(accentColor(for: streak.colorName))

            Text(streak.label)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)
                .lineLimit(2)
        }
        .frame(width: 130)
        .padding(Spacing.md)
        .background(backgroundColor(for: streak.colorName))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor(for: streak.colorName), lineWidth: 1)
        )
    }

    private func accentColor(for name: String) -> Color {
        switch name {
        case "success": return AppColors.success600
        case "primary": return AppColors.primary600
        case "tint": return AppColors.tint600
        case "secondary": return AppColors.secondary600
        default: return AppColors.primary600
        }
    }

    private func backgroundColor(for name: String) -> Color {
        switch name {
        case "success": return AppColors.success50
        case "primary": return AppColors.primary50
        case "tint": return AppColors.tint50
        case "secondary": return AppColors.secondary50
        default: return AppColors.primary50
        }
    }

    private func borderColor(for name: String) -> Color {
        switch name {
        case "success": return AppColors.success100
        case "primary": return AppColors.primary100
        case "tint": return AppColors.tint100
        case "secondary": return AppColors.secondary100
        default: return AppColors.primary100
        }
    }
}

#Preview {
    StreaksPreviewView()
}
