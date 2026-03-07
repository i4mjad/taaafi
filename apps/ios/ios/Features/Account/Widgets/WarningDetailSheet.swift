import SwiftUI

struct WarningDetailSheet: View {
    let warning: Warning
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                dragHandle

                headerSection

                reasonSection

                if let description = warning.description, !description.isEmpty {
                    descriptionSection(description)
                }

                infoGrid

                if let related = warning.relatedContent {
                    relatedContentSection(related)
                }

                guidelinesNotice
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppColors.grey300)
            .frame(width: 40, height: 4)
            .padding(.top, Spacing.sm)
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColors.warning50)
                    .frame(width: 64, height: 64)

                Image(systemName: AppIcon.warning.systemName)
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.warning600)
            }

            Text(Strings.Profile.warningDetail)
                .font(Typography.h5)
                .foregroundStyle(AppColors.grey900)
        }
    }

    private var reasonSection: some View {
        Text(warning.reason)
            .font(Typography.body)
            .foregroundStyle(AppColors.grey800)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(AppColors.grey50)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func descriptionSection(_ text: String) -> some View {
        Text(text)
            .font(Typography.footnote)
            .foregroundStyle(AppColors.grey700)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var infoGrid: some View {
        VStack(spacing: Spacing.sm) {
            detailRow(label: Strings.Profile.warningType, value: warning.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            detailRow(label: Strings.Profile.warningIssuedDate, value: warning.issuedAt.formatted(date: .abbreviated, time: .omitted))
            detailRow(label: Strings.Profile.warningStatus, value: warning.isActive ? Strings.Profile.active : Strings.Profile.inactive)
            detailRow(label: Strings.Profile.warningId, value: warning.id)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
            Spacer()
            Text(value)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey800)
        }
    }

    private func relatedContentSection(_ content: RelatedContent) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.relatedContent)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let title = content.title {
                    Text(title)
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey800)
                }
                Text("Type: \(content.type)")
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey600)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.primary50)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var guidelinesNotice: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: AppIcon.info.systemName)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.warning700)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Strings.Profile.importantNotice)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.warning800)

                Text(Strings.Profile.guidelinesNotice)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.warning700)
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warning50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
