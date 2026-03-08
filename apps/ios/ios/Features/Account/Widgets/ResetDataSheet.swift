import SwiftUI
import FirebaseAuth

struct ResetDataSheet: View {
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ResetDataViewModel?
    @State private var selectedDate = Date()
    @State private var resetToToday = false
    @State private var deleteFollowUps = false
    @State private var deleteEmotions = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text(Strings.Profile.resetDataDescription)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
                    .frame(maxWidth: .infinity, alignment: .leading)

                dateSection

                togglesSection

                Spacer()

                buttonsSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .navigationTitle(Strings.Profile.resetDataTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
        }
        .task {
            guard let uid = authService.currentUser?.uid else { return }
            viewModel = ResetDataViewModel(
                userFirstDate: userDocumentService.userDocument?.userFirstDate,
                userId: uid,
                userDocumentService: userDocumentService
            )
        }
    }

    // MARK: - Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.selectNewStartDate)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            if !resetToToday {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: selectedDate) { _, newValue in
                    viewModel?.selectedDate = newValue
                }
            }
        }
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        VStack(spacing: Spacing.sm) {
            Toggle(Strings.Profile.resetToToday, isOn: $resetToToday)
                .font(Typography.body)
                .tint(AppColors.primary)
                .onChange(of: resetToToday) { _, newValue in
                    viewModel?.resetToToday = newValue
                }

            Toggle(Strings.Profile.deleteFollowUps, isOn: $deleteFollowUps)
                .font(Typography.body)
                .tint(AppColors.error)
                .onChange(of: deleteFollowUps) { _, newValue in
                    viewModel?.deleteFollowUps = newValue
                }

            Toggle(Strings.Profile.deleteEmotions, isOn: $deleteEmotions)
                .font(Typography.body)
                .tint(AppColors.error)
                .onChange(of: deleteEmotions) { _, newValue in
                    viewModel?.deleteEmotions = newValue
                }
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Task { await handleConfirm() }
            } label: {
                Group {
                    if viewModel?.isSubmitting == true {
                        AppSpinner(tint: .white)
                    } else {
                        Text(Strings.Profile.resetConfirm)
                    }
                }
                .font(Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.error600)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel?.isSubmitting == true)
        }
    }

    private func handleConfirm() async {
        guard let result = await viewModel?.confirm(), result else {
            toastManager.show(.error, message: Strings.Account.error)
            return
        }
        toastManager.show(.success, message: Strings.Profile.resetSuccess)
        dismiss()
    }
}
