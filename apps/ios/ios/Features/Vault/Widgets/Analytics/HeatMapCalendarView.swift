import SwiftUI

struct HeatMapCalendarView: View {
    let data: [AnalyticsCalculator.DayHeat]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(data) { item in
                RoundedRectangle(cornerRadius: 2)
                    .fill(heatColor(item.intensity))
                    .frame(height: 24)
                    .overlay {
                        Text("\(Calendar.current.component(.day, from: item.id))")
                            .font(Typography.bodyTiny)
                            .foregroundStyle(item.intensity > 0.5 ? .white : AppColors.grey700)
                    }
            }
        }
    }

    private func heatColor(_ intensity: Double) -> Color {
        if intensity == 0 {
            return AppColors.success.opacity(0.15)
        }
        return AppColors.error.opacity(max(0.2, intensity))
    }
}
