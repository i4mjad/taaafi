import SwiftUI

struct BanDetailCard: View {
    let ban: Ban

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            badgesRow
            detailRows
        }
        .padding(Spacing.md)
        .background(AppColors.grey50)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.sm))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "shield.slash")
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AppColors.error600)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.xs))

            Text(Strings.Ban.details)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)
        }
    }

    // MARK: - Badges

    private var badgesRow: some View {
        HStack(spacing: Spacing.xs) {
            badge(
                text: ban.scope.displayText,
                color: ban.scope == .app_wide ? AppColors.error600 : AppColors.warning600
            )
            badge(
                text: ban.type.displayText,
                color: AppColors.grey600
            )
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(Typography.small)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Detail Rows

    private var detailRows: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            detailRow(icon: "exclamationmark.triangle", label: Strings.Ban.reason, value: ban.reason)

            if let desc = ban.description, !desc.isEmpty {
                detailRow(icon: "doc.text", label: Strings.Ban.description, value: desc)
            }

            detailRow(icon: "clock", label: Strings.Ban.duration, value: ban.formattedDuration)

            detailRow(icon: "calendar", label: Strings.Ban.issuedDate, value: ban.formattedIssuedDate)

            if let expiresDate = ban.formattedExpiresDate {
                detailRow(icon: "calendar.badge.clock", label: Strings.Ban.expiresOn, value: expiresDate)
            }

            detailRow(icon: "number", label: Strings.Ban.banId, value: ban.id)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.grey500)
                .frame(width: 20)

            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey800)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
