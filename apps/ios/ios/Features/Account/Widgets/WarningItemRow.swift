import SwiftUI

struct WarningItemRow: View {
    let warning: Warning

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                severityBadge
                Spacer()
                Text(warning.issuedAt, style: .date)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey600)
            }

            Text(warning.reason)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey900)
                .lineLimit(2)

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
        .background(AppColors.warning50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.warning200, lineWidth: 1)
        )
        .accessibilityLabel("Warning: \(warning.reason)")
    }

    private var severityBadge: some View {
        Text(warning.severity.rawValue.capitalized)
            .font(Typography.small)
            .fontWeight(.semibold)
            .foregroundStyle(severityColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(severityColor.opacity(0.1))
            .clipShape(Capsule())
    }

    private var severityColor: Color {
        switch warning.severity {
        case .low: AppColors.success600
        case .medium: AppColors.warning600
        case .high: AppColors.error600
        case .critical: AppColors.error800
        }
    }
}
