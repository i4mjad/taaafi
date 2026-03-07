import SwiftUI

struct DeletionInfoSection: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            infoRow(
                icon: AppIcon.person.systemName,
                title: Strings.Profile.deletionInfoUserData,
                description: Strings.Profile.deletionInfoUserDataDesc
            )
            infoRow(
                icon: AppIcon.listBullet.systemName,
                title: Strings.Profile.deletionInfoFollowUps,
                description: Strings.Profile.deletionInfoFollowUpsDesc
            )
            infoRow(
                icon: AppIcon.faceFrown.systemName,
                title: Strings.Profile.deletionInfoEmotions,
                description: Strings.Profile.deletionInfoEmotionsDesc
            )
            infoRow(
                icon: AppIcon.figureWalk.systemName,
                title: Strings.Profile.deletionInfoActivities,
                description: Strings.Profile.deletionInfoActivitiesDesc
            )
        }
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.error600)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.error600)

                Text(description)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey900)
            }
        }
    }
}
