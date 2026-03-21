import SwiftUI

struct StreakSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: StreakSettingsViewModel
    var onSave: (StreakDisplaySettings) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    startingDateInfo
                    displayModeSection
                    visibilitySection
                    saveButton
                }
                .padding(Spacing.md)
            }
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.streakSettings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
        }
    }

    // MARK: - Starting Date Info

    private var startingDateInfo: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.grey600)

            Text("\(Strings.Vault.startingDate): \(viewModel.userFirstDate.formatted(date: .abbreviated, time: .omitted))")
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey700)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(AppColors.grey50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
    }

    // MARK: - Display Mode

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Vault.streakDisplayMode)
                .font(Typography.body)
                .foregroundStyle(AppColors.grey600)

            Text(Strings.Vault.streakDisplayModeDesc)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)

            HStack(spacing: Spacing.xs) {
                displayModeCard(
                    mode: .days,
                    icon: "calendar",
                    title: Strings.Vault.daysOnly,
                    description: Strings.Vault.daysOnlyDesc
                )
                displayModeCard(
                    mode: .detailed,
                    icon: "clock",
                    title: Strings.Vault.detailedMode,
                    description: Strings.Vault.detailedModeDesc
                )
            }
        }
    }

    private func displayModeCard(mode: StreakDisplayMode, icon: String, title: String, description: String) -> some View {
        let isSelected = viewModel.settings.displayMode == mode

        return Button {
            viewModel.setDisplayMode(mode)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    Text(title)
                        .font(Typography.caption)
                }

                Text(description)
                    .font(Typography.small)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? AppColors.success : AppColors.grey600)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(isSelected ? AppColors.success.opacity(0.08) : AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AppColors.success : AppColors.grey200, lineWidth: 1)
            )
        }
    }

    // MARK: - Visibility Toggles

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Vault.statisticsVisibility)
                .font(Typography.body)
                .foregroundStyle(AppColors.grey600)

            Text(Strings.Vault.statisticsVisibilityDesc)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.xs) {
                visibilityToggle(type: .relapse, label: Strings.Vault.relapse)
                visibilityToggle(type: .pornOnly, label: Strings.Vault.pornOnly)
                visibilityToggle(type: .mastOnly, label: Strings.Vault.mastOnly)
                visibilityToggle(type: .slipUp, label: Strings.Vault.slipUp)
            }
        }
    }

    private func visibilityToggle(type: FollowUpType, label: String) -> some View {
        let isChecked = viewModel.isVisible(type)

        return Button {
            viewModel.toggleVisibility(type)
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(isChecked ? AppColors.primary : AppColors.grey400)

                Text(label)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey800)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.xxs)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.grey600, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            viewModel.save()
            onSave(viewModel.settings)
            dismiss()
        } label: {
            Text(Strings.Vault.save)
                .font(Typography.h6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
