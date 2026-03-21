import SwiftUI

struct StatisticsView: View {
    let statistics: UserStatistics

    var body: some View {
        VStack(spacing: Spacing.sm) {
            statisticRow(
                label: Strings.Vault.daysWithoutRelapse,
                value: "\(statistics.daysWithoutRelapse)",
                icon: "flame.fill",
                color: AppColors.success
            )

            Divider()

            statisticRow(
                label: Strings.Vault.relapsesLast30Days,
                value: "\(statistics.relapsesInLast30Days)",
                icon: "chart.bar.fill",
                color: AppColors.error
            )

            Divider()

            statisticRow(
                label: Strings.Vault.longestStreak,
                value: "\(statistics.longestRelapseStreak)",
                icon: "trophy.fill",
                color: AppColors.warning
            )
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 0.5)
        )
    }

    private func statisticRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)

            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey700)

            Spacer()

            Text(value)
                .font(Typography.h5)
                .foregroundStyle(color)
        }
    }
}
