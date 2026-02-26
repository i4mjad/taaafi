import SwiftUI

enum DatePickerMode {
    case date
    case time
    case dateTime

    var components: DatePickerComponents {
        switch self {
        case .date: return .date
        case .time: return .hourAndMinute
        case .dateTime: return [.date, .hourAndMinute]
        }
    }
}

struct AppDatePicker: View {
    @Binding var value: Date?
    let label: String
    var mode: DatePickerMode = .date
    var range: ClosedRange<Date>?
    var formatter: DateFormatter = .default

    @State private var isPresented = false
    @State private var tempDate = Date()

    var body: some View {
        Button {
            tempDate = getValidInitialDate(
                first: range?.lowerBound,
                last: range?.upperBound,
                current: value
            )
            isPresented = true
            HapticService.selectionClick()
        } label: {
            HStack {
                Text(label)
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey900)

                Spacer()

                Text(value.map { formatter.string(from: $0) } ?? "—")
                    .font(Typography.body)
                    .foregroundStyle(value != nil ? AppColors.primary : AppColors.grey400)

                Image(systemName: AppIcon.chevronRight.systemName)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.grey400)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            pickerSheet
        }
    }

    private var pickerSheet: some View {
        NavigationStack {
            VStack {
                if let range {
                    DatePicker("", selection: $tempDate, in: range, displayedComponents: mode.components)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                } else {
                    DatePicker("", selection: $tempDate, displayedComponents: mode.components)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        value = tempDate
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    static func getValidInitialDate(
        first: Date?,
        last: Date?,
        current: Date?
    ) -> Date {
        let now = Date()
        let date = current ?? now

        if let first, date < first {
            return first
        }
        if let last, date > last {
            return last
        }
        return date
    }
}

private extension DateFormatter {
    static let `default`: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
