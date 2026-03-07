import SwiftUI

struct SubscriptionCard: View {
    let isPlusUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader

            if isPlusUser {
                plusCard
            } else {
                freeCard
            }
        }
    }

    private var sectionHeader: some View {
        Text(Strings.Profile.subscription)
            .font(Typography.h6)
            .foregroundStyle(AppColors.grey900)
    }

    private var plusCard: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColors.primary50)
                    .frame(width: 40, height: 40)
                Image(systemName: AppIcon.checkCircle.systemName)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primary600)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Strings.Profile.plusActive)
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary600)
            }

            Spacer()

            Image(AppIcon.plusIconName)
                .resizable()
                .scaledToFit()
                .frame(height: 24)
        }
        .padding(Spacing.md)
        .background(AppColors.primary50)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.primary200, lineWidth: 1)
        )
    }

    private var freeCard: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColors.grey100)
                    .frame(width: 40, height: 40)
                Image(systemName: AppIcon.person.systemName)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.grey500)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Strings.Profile.freePlan)
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.grey900)

                Text(Strings.Profile.freePlanDescription)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey500)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
    }
}
