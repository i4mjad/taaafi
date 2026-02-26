//
//  CommunityActivitySection.swift
//  ios
//

import SwiftUI

struct CommunityActivitySection: View {
    @Environment(ToastManager.self) private var toastManager

    private struct ActivityCard: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }

    private let cards: [ActivityCard] = [
        ActivityCard(
            icon: "safari",
            title: String(localized: "home.community.discover"),
            subtitle: String(localized: "home.community.discoverSubtitle")
        ),
        ActivityCard(
            icon: "square.and.pencil",
            title: String(localized: "home.community.shareStory"),
            subtitle: String(localized: "home.community.shareStorySubtitle")
        ),
        ActivityCard(
            icon: "heart",
            title: String(localized: "home.community.needSupport"),
            subtitle: String(localized: "home.community.needSupportSubtitle")
        ),
        ActivityCard(
            icon: "square.grid.2x2",
            title: String(localized: "home.community.browseCategories"),
            subtitle: String(localized: "home.community.browseCategoriesSubtitle")
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "home.community"))
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey800)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(cards) { card in
                        communityCard(card)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private func communityCard(_ card: ActivityCard) -> some View {
        Button {
            HapticService.lightImpact()
            toastManager.show(.info, message: String(localized: "home.comingSoon"))
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: card.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary50)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(card.title)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey800)

                Text(card.subtitle)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey500)
                    .lineLimit(2)
            }
            .frame(width: 150, alignment: .leading)
            .padding(Spacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.grey200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CommunityActivitySection()
        .environment(ToastManager())
}
