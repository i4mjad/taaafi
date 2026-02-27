import SwiftUI

struct StreaksView: View {
    let streaks: StreakStatistics

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            streakCard(
                label: Strings.Vault.relapseStreak,
                days: streaks.relapseStreak,
                color: AppColors.success
            )
            streakCard(
                label: Strings.Vault.pornOnlyStreak,
                days: streaks.pornOnlyStreak,
                color: .purple
            )
            streakCard(
                label: Strings.Vault.mastOnlyStreak,
                days: streaks.mastOnlyStreak,
                color: .orange
            )
            streakCard(
                label: Strings.Vault.slipUpStreak,
                days: streaks.slipUpStreak,
                color: AppColors.error
            )
        }
    }

    private func streakCard(label: String, days: Int, color: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(days)")
                .font(Typography.h3)
                .foregroundStyle(color)

            Text(Strings.Vault.days)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey500)

            Text(label)
                .font(Typography.small)
                .foregroundStyle(AppColors.grey700)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
