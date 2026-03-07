import SwiftUI

struct RetentionOfferCard: View {
    let onClaim: () -> Void
    let onSkip: () -> Void
    var isClaiming: Bool = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            giftIcon

            badgeCapsule

            Text(Strings.Profile.retentionTitle)
                .font(Typography.h5)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(Strings.Profile.retentionDescription)
                .font(Typography.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            claimButton

            skipButton
        }
        .padding(Spacing.xl)
        .background(
            LinearGradient(
                colors: [AppColors.primary600, AppColors.primary700],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppColors.primary600.opacity(0.3), radius: 8, y: 4)
    }

    private var giftIcon: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 56, height: 56)

            Image(systemName: AppIcon.gift.systemName)
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
    }

    private var badgeCapsule: some View {
        Text(Strings.Profile.retentionBadge)
            .font(Typography.small)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
    }

    private var claimButton: some View {
        Button(action: onClaim) {
            HStack(spacing: Spacing.xs) {
                if isClaiming {
                    AppSpinner(tint: AppColors.primary600)
                } else {
                    Image(systemName: AppIcon.sparkles.systemName)
                    Text(Strings.Profile.claimReward)
                }
            }
            .font(Typography.body)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.primary600)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isClaiming)
        .accessibilityLabel(Strings.Profile.claimReward)
    }

    private var skipButton: some View {
        Button(action: onSkip) {
            Text(Strings.Profile.skipOffer)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey500)
                .underline()
        }
    }
}
