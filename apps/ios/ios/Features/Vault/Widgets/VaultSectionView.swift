import SwiftUI

struct VaultSectionView<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let content: Content

    init(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey700)
            }

            Text(description)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey500)

            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
