import SwiftUI

struct SmartAlertsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: SmartAlertsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        headerSection
                        eligibilitySection
                        if settings.isEligible {
                            toggleSection
                            if settings.isEnabled {
                                timePickerSection
                            }
                        }
                        saveButton
                    }
                }
                .padding(Spacing.md)
            }
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.smartAlertsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
            .task {
                await viewModel.loadSettings()
            }
        }
    }

    private var settings: SmartAlertSettings { viewModel.settings }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "shield.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Vault.smartAlertsTitle)
                    .font(Typography.h5)
                    .foregroundStyle(AppColors.grey900)
                Text(Strings.Vault.smartAlertsDesc)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey600)
            }
        }
    }

    // MARK: - Eligibility

    private var eligibilitySection: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: settings.isEligible ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(settings.isEligible ? AppColors.success : AppColors.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.isEligible ? Strings.Vault.smartAlertsEligible : Strings.Vault.smartAlertsNotEligible)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(settings.isEligible ? AppColors.success : AppColors.warning)

                if let reason = viewModel.eligibilityReasonText {
                    Text(reason)
                        .font(Typography.small)
                        .foregroundStyle(AppColors.grey600)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(settings.isEligible ? AppColors.success.opacity(0.08) : AppColors.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        Toggle(isOn: Binding(
            get: { viewModel.settings.isEnabled },
            set: { _ in viewModel.toggleEnabled() }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Vault.enableSmartAlerts)
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey800)
            }
        }
        .tint(AppColors.primary)
        .padding(Spacing.sm)
        .background(AppColors.grey50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Time Picker

    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Vault.alertTime)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.settings.alertTime ?? Date() },
                    set: { viewModel.setAlertTime($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save()
                dismiss()
            }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(Strings.Vault.save)
                }
            }
            .font(Typography.h6)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(viewModel.isSaving)
    }
}
