import SwiftUI
import Charts

struct RiskClockView: View {
    let data: [AnalyticsCalculator.HourlyRisk]

    var body: some View {
        if #available(iOS 17.0, *) {
            chartView
                .frame(height: 200)
        } else {
            fallbackView
        }
    }

    @available(iOS 17.0, *)
    private var chartView: some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Count", max(item.count, 0)),
                innerRadius: .ratio(0.5),
                angularInset: 1
            )
            .foregroundStyle(by: .value("Hour", hourLabel(item.id)))
            .cornerRadius(2)
        }
        .chartLegend(.hidden)
        .overlay {
            VStack(spacing: 2) {
                if let peak = data.max(by: { $0.count < $1.count }), peak.count > 0 {
                    Text(hourLabel(peak.id))
                        .font(Typography.h6)
                        .foregroundStyle(AppColors.error)
                    Text(Strings.Vault.riskClock)
                        .font(Typography.bodyTiny)
                        .foregroundStyle(AppColors.grey500)
                }
            }
        }
    }

    private var fallbackView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.xxs) {
            ForEach(data) { item in
                VStack(spacing: 2) {
                    Text(hourLabel(item.id))
                        .font(Typography.bodyTiny)
                        .foregroundStyle(AppColors.grey500)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensity(for: item))
                        .frame(height: 20)
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = hour < 12 ? "ha" : "ha"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date)
    }

    private func intensity(for item: AnalyticsCalculator.HourlyRisk) -> Color {
        let maxCount = max(1, data.map(\.count).max() ?? 1)
        let ratio = Double(item.count) / Double(maxCount)
        return AppColors.error.opacity(max(0.1, ratio))
    }
}
