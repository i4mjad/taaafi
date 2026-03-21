import SwiftUI

struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    let data: VaultHelpData
    @State private var selectedTab: HelpTab = .howToRead

    enum HelpTab: String {
        case howToRead
        case howToUse
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with icon
                HStack(spacing: Spacing.sm) {
                    Image(systemName: data.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(data.iconColor)

                    Text(String(localized: String.LocalizationValue(data.titleKey)))
                        .font(Typography.h5)
                        .foregroundStyle(AppColors.grey900)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                // Segmented control (if "How to Use" exists)
                if data.howToUseSections != nil {
                    Picker("", selection: $selectedTab) {
                        Text(Strings.Vault.howToRead).tag(HelpTab.howToRead)
                        Text(Strings.Vault.howToUse).tag(HelpTab.howToUse)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                Divider()

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ForEach(currentSections) { section in
                            helpSectionView(section)
                        }
                    }
                    .padding(Spacing.md)
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
                            .padding(6)
                            .background(AppColors.grey100)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    private var currentSections: [HelpSectionData] {
        if selectedTab == .howToUse, let useSections = data.howToUseSections {
            return useSections
        }
        return data.howToReadSections
    }

    // MARK: - Section View

    private func helpSectionView(_ section: HelpSectionData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !section.titleKey.isEmpty {
                HStack(spacing: Spacing.xs) {
                    if let icon = section.icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(section.iconColor ?? AppColors.primary)
                    }

                    Text(String(localized: String.LocalizationValue(section.titleKey)))
                        .font(Typography.h6)
                        .foregroundStyle(AppColors.grey900)
                }
            }

            ForEach(section.items) { item in
                helpItemView(item)
            }
        }
    }

    // MARK: - Item View

    private func helpItemView(_ item: HelpItemData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !item.titleKey.isEmpty {
                HStack(spacing: Spacing.xs) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(item.iconColor ?? AppColors.primary)
                    }

                    Text(String(localized: String.LocalizationValue(item.titleKey)))
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.grey900)
                }
            }

            Text(String(localized: String.LocalizationValue(item.descriptionKey)))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey700)
                .fixedSize(horizontal: false, vertical: true)

            // Recovery benefit
            if !item.recoveryBenefitKey.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.success)

                    Text(String(localized: String.LocalizationValue(item.recoveryBenefitKey)))
                        .font(Typography.small)
                        .foregroundStyle(AppColors.success700)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.sm)
                .background(AppColors.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.success200, lineWidth: 1)
                )
            }
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
