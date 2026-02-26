//
//  CalendarPreviewView.swift
//  ios
//

import SwiftUI

struct CalendarPreviewView: View {
    private let highlightedDates = MockHomeData.calendarDates
    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private var currentMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }

        let firstDayWeekday = calendar.component(.weekday, from: currentMonth)
        let leadingEmptyDays = firstDayWeekday - calendar.firstWeekday
        let adjustedLeading = leadingEmptyDays < 0 ? leadingEmptyDays + 7 : leadingEmptyDays

        var days: [Date?] = Array(repeating: nil, count: adjustedLeading)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: currentMonth) {
                days.append(date)
            }
        }

        return days
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "home.calendar"))
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey800)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.xs) {
                Text(monthTitle)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey700)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(Typography.bodyTiny)
                            .foregroundStyle(AppColors.grey400)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let day = calendar.component(.day, from: date)
                            let isHighlighted = isDateHighlighted(date)
                            let isToday = calendar.isDateInToday(date)

                            Text("\(day)")
                                .font(Typography.caption)
                                .foregroundStyle(isToday ? .white : AppColors.grey700)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isToday ? AppColors.primary : (isHighlighted ? AppColors.success100 : Color.clear))
                                )
                                .overlay(
                                    Group {
                                        if isHighlighted && !isToday {
                                            Circle()
                                                .fill(AppColors.success)
                                                .frame(width: 5, height: 5)
                                                .offset(y: 12)
                                        }
                                    }
                                )
                        } else {
                            Text("")
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.grey200, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.md)
        }
    }

    private func isDateHighlighted(_ date: Date) -> Bool {
        highlightedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}

#Preview {
    CalendarPreviewView()
}
