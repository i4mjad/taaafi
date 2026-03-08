import SwiftUI

struct AccountSettingsRow<Trailing: View>: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    var action: () -> Void = {}
    @ViewBuilder var trailing: () -> Trailing

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

                trailing()
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension AccountSettingsRow where Trailing == DefaultChevron {
    init(
        icon: String,
        label: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.label = label
        self.isDestructive = isDestructive
        self.action = action
        self.trailing = { DefaultChevron() }
    }
}

struct DefaultChevron: View {
    var body: some View {
        Image(systemName: AppIcon.chevronRight.systemName)
            .font(.system(size: 14))
            .foregroundStyle(AppColors.grey400)
    }
}
