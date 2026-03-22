import SwiftUI

struct StreaksView: View {
    let streaks: StreakStatistics
    var settings: StreakDisplaySettings = .defaultSettings
    var onStreakTap: ((FollowUpType) -> Void)?
    var onCustomizeTap: (() -> Void)?
    var onResetTap: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            streakCards
            actionsRow
        }
    }

    // MARK: - Streak Cards

    private var streakCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            if settings.visibility.relapse {
                streakCard(
                    label: Strings.Vault.relapseStreak,
                    days: streaks.relapseStreak,
                    color: AppColors.success,
                    type: .relapse
                )
            }
            if settings.visibility.pornOnly {
                streakCard(
                    label: Strings.Vault.pornOnlyStreak,
                    days: streaks.pornOnlyStreak,
                    color: .purple,
                    type: .pornOnly
                )
            }
            if settings.visibility.mastOnly {
                streakCard(
                    label: Strings.Vault.mastOnlyStreak,
                    days: streaks.mastOnlyStreak,
                    color: .orange,
                    type: .mastOnly
                )
            }
            if settings.visibility.slipUp {
                streakCard(
                    label: Strings.Vault.slipUpStreak,
                    days: streaks.slipUpStreak,
                    color: AppColors.error,
                    type: .slipUp
                )
            }
        }
    }

    private func streakCard(label: String, days: Int, color: Color, type: FollowUpType) -> some View {
        Button {
            onStreakTap?(type)
        } label: {
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

    // MARK: - Actions Row

    private var actionsRow: some View {
        HStack(spacing: Spacing.xs) {
            Button {
                onCustomizeTap?()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                    Text(Strings.Vault.customize)
                        .font(Typography.footnote)
                }
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.primary300, lineWidth: 1)
                )
            }

            Button {
                onResetTap?()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                    Text(Strings.Vault.resetCounters)
                        .font(Typography.footnote)
                }
                .foregroundStyle(AppColors.warning)
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.warning300, lineWidth: 1)
                )
            }
        }
    }
}
