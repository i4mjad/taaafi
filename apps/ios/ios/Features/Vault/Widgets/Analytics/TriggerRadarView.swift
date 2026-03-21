import SwiftUI
import Charts

struct TriggerRadarView: View {
    let data: [AnalyticsCalculator.TriggerCount]

    var body: some View {
        if data.isEmpty {
            Text(Strings.Vault.noTriggersRecorded)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        } else if #available(iOS 17.0, *) {
            chartView
                .frame(height: 200)
        } else {
            fallbackView
        }
    }

    @available(iOS 17.0, *)
    private var chartView: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Trigger", localizedTrigger(item.trigger))
            )
            .foregroundStyle(AppColors.primary.gradient)
            .cornerRadius(4)
        }
        .chartXAxis(.hidden)
    }

    private var fallbackView: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(data) { item in
                HStack(spacing: Spacing.sm) {
                    Text(localizedTrigger(item.trigger))
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey700)
                        .frame(width: 80, alignment: .trailing)

                    GeometryReader { geometry in
                        let maxCount = max(1, data.first?.count ?? 1)
                        let width = geometry.size.width * Double(item.count) / Double(maxCount)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.primary)
                            .frame(width: max(4, width), height: 16)
                    }
                    .frame(height: 16)

                    Text("\(item.count)")
                        .font(Typography.bodyTiny)
                        .foregroundStyle(AppColors.grey500)
                        .frame(width: 24)
                }
            }
        }
    }

    private func localizedTrigger(_ key: String) -> String {
        String(localized: String.LocalizationValue("vault.trigger." + key))
    }
}
