import SwiftUI

struct VaultCalendarView: View {
    let followUps: [FollowUpModel]
    let userFirstDate: Date
    @Binding var selectedMonth: Date
    let onDateTap: (Date) -> Void

    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let daysOfWeek = ["أحد", "اثن", "ثلا", "أرب", "خمي", "جمع", "سبت"]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            monthHeader
            weekdayHeader
            daysGrid
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 0.5)
        )
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                }
            } label: {
                Image(systemName: AppIcon.chevronForward.systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }

            Spacer()

            Text(monthYearString)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)

            Spacer()

            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey500)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let days = daysInMonth()
        let firstWeekday = firstDayOfMonthWeekday()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
            // Empty cells for days before month starts
            ForEach(0..<firstWeekday, id: \.self) { _ in
                Text("")
                    .frame(height: 36)
            }

            // Day cells
            ForEach(days, id: \.self) { date in
                dayCell(for: date)
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        let followUpTypes = followUpsForDate(date)

        return Button {
            if !isFuture && date >= userFirstDate {
                onDateTap(date)
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(Typography.footnote)
                    .foregroundStyle(isFuture ? AppColors.grey300 : AppColors.grey700)
                    .frame(width: 30, height: 30)
                    .background(isToday ? AppColors.primary.opacity(0.15) : Color.clear)
                    .clipShape(Circle())

                // Follow-up dot indicator
                if !followUpTypes.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(followUpTypes.prefix(3)), id: \.self) { type in
                            Circle()
                                .fill(colorForType(type))
                                .frame(width: 4, height: 4)
                        }
                    }
                } else if !isFuture && date >= calendar.startOfDay(for: userFirstDate) {
                    Circle()
                        .fill(AppColors.success.opacity(0.6))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 36)
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: selectedMonth)
    }

    private func daysInMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else { return [] }
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        return range.compactMap { day in
            calendar.date(from: DateComponents(year: components.year, month: components.month, day: day))
        }
    }

    private func firstDayOfMonthWeekday() -> Int {
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let firstDay = calendar.date(from: components) else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    private func followUpsForDate(_ date: Date) -> [FollowUpType] {
        let startOfDay = calendar.startOfDay(for: date)
        return followUps
            .filter { calendar.startOfDay(for: $0.time) == startOfDay }
            .map(\.type)
    }

    private func colorForType(_ type: FollowUpType) -> Color {
        switch type {
        case .relapse: return AppColors.grey500
        case .pornOnly: return .purple
        case .mastOnly: return .orange
        case .slipUp: return AppColors.error
        case .none: return AppColors.success
        }
    }
}
