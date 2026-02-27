import SwiftUI

struct VaultLayoutSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: VaultLayoutSettingsViewModel
    var onDismiss: (VaultLayoutSettings) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            List {
                tabOrderSection
                sectionOrderSection
                resetSection
            }
            .navigationTitle(Strings.Vault.layoutSettings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Strings.Common.done) {
                        onDismiss(viewModel.currentSettings)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Tab Order

    private var tabOrderSection: some View {
        Section(Strings.Vault.tabOrder) {
            ForEach(viewModel.tabOrder) { tab in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(tab.color)
                        .frame(width: 24)

                    Text(tab.label)
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey700)

                    Spacer()

                    if tab != .vault {
                        Toggle("", isOn: Binding(
                            get: { !viewModel.hiddenTabs.contains(tab) },
                            set: { _ in viewModel.toggleTabVisibility(tab) }
                        ))
                        .labelsHidden()
                        .tint(AppColors.primary)
                    }
                }
            }
            .onMove { source, destination in
                viewModel.moveTab(from: source, to: destination)
            }
        }
    }

    // MARK: - Section Order

    private var sectionOrderSection: some View {
        Section(Strings.Vault.sectionOrder) {
            ForEach(viewModel.sectionOrder) { section in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: section.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(section.color)
                        .frame(width: 24)

                    VStack(alignment: .leading) {
                        Text(section.label)
                            .font(Typography.body)
                            .foregroundStyle(AppColors.grey700)

                        if section.isPremium {
                            Text(Strings.Premium.upgradeToPlus)
                                .font(Typography.bodyTiny)
                                .foregroundStyle(.orange)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { !viewModel.hiddenSections.contains(section) },
                        set: { _ in viewModel.toggleSectionVisibility(section) }
                    ))
                    .labelsHidden()
                    .tint(AppColors.primary)
                }
            }
            .onMove { source, destination in
                viewModel.moveSection(from: source, to: destination)
            }
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Button(Strings.Vault.resetToDefault) {
                viewModel.resetToDefault()
            }
            .foregroundStyle(AppColors.error)
        }
    }
}
