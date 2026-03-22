import SwiftUI

struct VaultInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppColors.primary)
                        .padding(.top, Spacing.md)

                    Text(Strings.Vault.vaultFeatures)
                        .font(Typography.h5)
                        .foregroundStyle(AppColors.grey900)

                    VStack(spacing: Spacing.md) {
                        featureSection(
                            icon: "checklist",
                            iconColor: AppColors.primary,
                            title: Strings.Vault.activities,
                            description: Strings.Vault.activitiesInfoDesc
                        )

                        featureSection(
                            icon: "book.fill",
                            iconColor: .purple,
                            title: Strings.Vault.libraryTitle,
                            description: Strings.Vault.libraryInfoDesc
                        )

                        featureSection(
                            icon: "pencil.line",
                            iconColor: .cyan,
                            title: Strings.Vault.diariesTitle,
                            description: Strings.Vault.diariesInfoDesc
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.grey600)
                    }
                }
            }
        }
    }

    private func featureSection(icon: String, iconColor: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey900)
            }

            Text(description)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey600)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(AppColors.grey50)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
    }
}
