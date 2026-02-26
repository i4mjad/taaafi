import SwiftUI

struct RadioOption<T: Hashable>: Identifiable {
    let id = UUID()
    let value: T
    let title: String
    var subtitle: String?
}

struct AppRadio<T: Hashable>: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? AppColors.primary : Color.clear)
            .overlay(
                Circle()
                    .stroke(isSelected ? AppColors.primary : AppColors.grey300, lineWidth: 1.5)
            )
            .overlay {
                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 22, height: 22)
    }
}

struct AppRadioGroup<T: Hashable>: View {
    @Binding var selection: T
    let options: [RadioOption<T>]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Button {
                    selection = option.value
                    HapticService.selectionClick()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        AppRadio<T>(isSelected: selection == option.value)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(option.title)
                                .font(Typography.body)
                                .foregroundStyle(AppColors.grey900)

                            if let subtitle = option.subtitle {
                                Text(subtitle)
                                    .font(Typography.caption)
                                    .foregroundStyle(AppColors.grey500)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)

                if index < options.count - 1 {
                    Divider()
                }
            }
        }
    }
}
