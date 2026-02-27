import SwiftUI

struct StreakAveragesCard: View {
    let averages: AnalyticsCalculator.StreakAverages

    var body: some View {
        VStack(spacing: Spacing.sm) {
            averageBar(label: Strings.Vault.sevenDays, value: averages.sevenDay, color: AppColors.success)
            averageBar(label: Strings.Vault.thirtyDays, value: averages.thirtyDay, color: AppColors.primary)
            averageBar(label: Strings.Vault.ninetyDays, value: averages.ninetyDay, color: .indigo)
        }
    }

    private func averageBar(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(label)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey700)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(Typography.h6)
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.grey100)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
