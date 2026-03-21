import SwiftUI

struct WarningNotificationBanner: View {
    let totalWarnings: Int
    var onTap: () -> Void = {}

    var body: some View {
        if totalWarnings > 0 {
            Button {
                HapticService.lightImpact()
                onTap()
            } label: {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.warning100)
                            .frame(width: 36, height: 36)

                        Image(systemName: AppIcon.warning.systemName)
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.warning700)
                    }

                    Text(String(format: Strings.Banner.warningCount, totalWarnings))
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.warning800)

                    Spacer()

                    Image(systemName: AppIcon.chevronForward.systemName)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.grey400)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs + 2)
                .background(AppColors.warning50)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.warning300, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }
}
