import SwiftUI

struct AccountSettingsRow: View {
    let icon: String
    let label: String
    var trailing: AnyView?
    var isDestructive: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isDestructive ? AppColors.error : AppColors.grey600)
                    .frame(width: 24, alignment: .center)

                Text(label)
                    .font(Typography.body)
                    .foregroundStyle(isDestructive ? AppColors.error : AppColors.grey900)

                Spacer()

                if let trailing {
                    trailing
                } else {
                    Image(systemName: AppIcon.chevronRight.systemName)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.grey400)
                }
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
