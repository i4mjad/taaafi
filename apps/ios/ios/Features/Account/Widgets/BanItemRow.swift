import SwiftUI

struct BanItemRow: View {
    let ban: Ban

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                scopeBadge
                Spacer()
                Text(ban.issuedAt, style: .date)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey600)
            }

            Text(ban.reason)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey900)
                .lineLimit(2)

            if let expiresAt = ban.expiresAt {
                Text("\(Strings.Ban.duration): \(expiresAt, style: .relative)")
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey600)
            } else {
                Text(Strings.Ban.permanent)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.error600)
            }

            HStack(spacing: Spacing.xxs) {
                Image(systemName: AppIcon.chevronRight.systemName)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.grey400)
                Text(Strings.Ban.details)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey500)
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.error50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.error200, lineWidth: 1)
        )
        .accessibilityLabel("Ban: \(ban.reason)")
    }

    private var scopeBadge: some View {
        Text(ban.scope == .app_wide ? Strings.Ban.scopeAppWide : Strings.Ban.scopeFeature)
            .font(Typography.small)
            .fontWeight(.semibold)
            .foregroundStyle(ban.scope == .app_wide ? AppColors.error600 : AppColors.warning600)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background((ban.scope == .app_wide ? AppColors.error600 : AppColors.warning600).opacity(0.1))
            .clipShape(Capsule())
    }
}
