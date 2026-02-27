import SwiftUI

struct FollowUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: FollowUpSheetViewModel
    var onSaved: () -> Void = {}

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                datePickerHeader
                Divider()
                stepContent
                Divider()
                bottomBar
            }
            .navigationTitle(Strings.Vault.dailyFollowUp)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
        }
    }

    // MARK: - Date Picker

    private var datePickerHeader: some View {
        DatePicker(
            "",
            selection: $viewModel.selectedDate,
            in: ...Date(),
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .padding(Spacing.md)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                switch viewModel.currentStep {
                case .selectType:
                    typeSelectionView
                case .selectTriggers:
                    TriggerPickerView(selectedTriggers: $viewModel.selectedTriggers)
                case .selectEmotions:
                    EmotionPickerView(selectedEmotions: $viewModel.selectedEmotions)
                case .notes:
                    notesView
                }
            }
            .padding(Spacing.md)
        }
    }

    // MARK: - Type Selection

    private var typeSelectionView: some View {
        VStack(spacing: Spacing.sm) {
            Text(Strings.Vault.selectType)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Free Day button
            Button {
                viewModel.selectFreeDay()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                    Text(Strings.Vault.freeDay)
                        .font(Typography.body)
                }
                .foregroundStyle(viewModel.isFreeDay ? .white : AppColors.success)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(viewModel.isFreeDay ? AppColors.success : AppColors.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if viewModel.isFreeDay {
                Text(Strings.Vault.freeDaySuccess)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.success)
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Follow-up type buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.xs) {
                followUpTypeButton(.slipUp, icon: "arrow.down.right", color: AppColors.error)
                followUpTypeButton(.relapse, icon: "heart.slash.fill", color: AppColors.grey500)
                followUpTypeButton(.pornOnly, icon: "play.fill", color: .purple)
                followUpTypeButton(.mastOnly, icon: "hand.raised.fill", color: .orange)
            }

            if viewModel.selectedTypes.contains(.relapse) {
                Toggle(Strings.Vault.addAllFollowUps, isOn: $viewModel.addAllFollowUps)
                    .font(Typography.footnote)
                    .tint(AppColors.primary)
                    .padding(.top, Spacing.xs)
            }
        }
    }

    private func followUpTypeButton(_ type: FollowUpType, icon: String, color: Color) -> some View {
        let isSelected = viewModel.selectedTypes.contains(type)

        return Button {
            viewModel.selectType(type)
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(labelForType(type))
                    .font(Typography.footnote)
            }
            .foregroundStyle(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func labelForType(_ type: FollowUpType) -> String {
        switch type {
        case .relapse: return Strings.Vault.relapse
        case .pornOnly: return Strings.Vault.pornOnly
        case .mastOnly: return Strings.Vault.mastOnly
        case .slipUp: return Strings.Vault.slipUp
        case .none: return Strings.Vault.noIncident
        }
    }

    // MARK: - Notes

    private var notesView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Vault.addNotes)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)

            TextEditor(text: $viewModel.notes)
                .font(Typography.body)
                .frame(minHeight: 120)
                .padding(Spacing.xs)
                .background(AppColors.grey50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: Spacing.sm) {
            if viewModel.currentStep != .selectType {
                Button {
                    viewModel.goBack()
                } label: {
                    Text(Strings.Common.cancel)
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey500)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColors.grey100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button {
                if viewModel.isLastStep {
                    Task {
                        await viewModel.save()
                        onSaved()
                        dismiss()
                    }
                } else {
                    viewModel.goToNext()
                }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.isLastStep ? Strings.Vault.save : Strings.Common.done)
                            .font(Typography.body)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(viewModel.canProceed ? AppColors.primary : AppColors.grey300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canProceed || viewModel.isSaving)
        }
        .padding(Spacing.md)
    }
}
