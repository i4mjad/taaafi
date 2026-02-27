import SwiftUI
import Charts

struct MoodCorrelationView: View {
    let data: [AnalyticsCalculator.MoodCorrelation]

    var body: some View {
        if data.isEmpty {
            Text(Strings.Vault.noEmotions)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        } else if #available(iOS 17.0, *) {
            chartView
                .frame(height: 220)
        } else {
            fallbackView
        }
    }

    @available(iOS 17.0, *)
    private var chartView: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Emotion", "\(item.emoji) \(item.emotionName)"),
                    y: .value("Count", item.cleanCount)
                )
                .foregroundStyle(AppColors.success)
                .position(by: .value("Type", Strings.Vault.cleanDays))

                BarMark(
                    x: .value("Emotion", "\(item.emoji) \(item.emotionName)"),
                    y: .value("Count", item.relapseCount)
                )
                .foregroundStyle(AppColors.error)
                .position(by: .value("Type", Strings.Vault.relapseDays))
            }
        }
        .chartForegroundStyleScale([
            Strings.Vault.cleanDays: AppColors.success,
            Strings.Vault.relapseDays: AppColors.error,
        ])
    }

    private var fallbackView: some View {
        VStack(spacing: Spacing.xs) {
            // Legend
            HStack(spacing: Spacing.md) {
                legendDot(color: AppColors.success, label: Strings.Vault.cleanDays)
                legendDot(color: AppColors.error, label: Strings.Vault.relapseDays)
            }

            ForEach(data) { item in
                HStack(spacing: Spacing.xs) {
                    Text(item.emoji)
                        .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppColors.success)
                                .frame(width: barWidth(item.cleanCount), height: 8)
                            Text("\(item.cleanCount)")
                                .font(Typography.bodyTiny)
                                .foregroundStyle(AppColors.grey500)
                        }
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppColors.error)
                                .frame(width: barWidth(item.relapseCount), height: 8)
                            Text("\(item.relapseCount)")
                                .font(Typography.bodyTiny)
                                .foregroundStyle(AppColors.grey500)
                        }
                    }
                }
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(Typography.bodyTiny)
                .foregroundStyle(AppColors.grey500)
        }
    }

    private func barWidth(_ count: Int) -> CGFloat {
        let maxCount = max(1, data.flatMap { [$0.cleanCount, $0.relapseCount] }.max() ?? 1)
        return max(4, CGFloat(count) / CGFloat(maxCount) * 100)
    }
}
