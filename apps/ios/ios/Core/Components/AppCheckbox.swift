import SwiftUI

struct AppCheckbox: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
            HapticService.selectionClick()
        } label: {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isChecked ? AppColors.primary : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(isChecked ? AppColors.primary : AppColors.grey300, lineWidth: 1.5)
                )
                .overlay {
                    if isChecked {
                        Image(systemName: AppIcon.check.systemName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}

struct AppCheckboxRow: View {
    @Binding var isChecked: Bool
    let title: String
    var subtitle: String?

    var body: some View {
        Button {
            isChecked.toggle()
            HapticService.selectionClick()
        } label: {
            HStack(spacing: Spacing.sm) {
                AppCheckbox(isChecked: $isChecked)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey900)

                    if let subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(AppColors.grey500)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
