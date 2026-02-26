import SwiftUI
import FirebaseAuth

/// Screen for legacy users to confirm/complete their profile details
struct ConfirmUserDetailsScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(ToastManager.self) private var toastManager

    @State private var viewModel = ConfirmDetailsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    formContent
                }
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "confirmDetails.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                viewModel.loadFromDocument(userDocumentService.userDocument)
            }
        }
    }

    // MARK: - Form

    private var formContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text(String(localized: "confirmDetails.description"))
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey500)
                    .multilineTextAlignment(.center)

                AppTextField(
                    text: $viewModel.displayName,
                    label: String(localized: "registration.name"),
                    maxLength: 50,
                    validator: { _ in viewModel.nameError }
                )

                AppTextField(
                    text: $viewModel.email,
                    label: String(localized: "auth.email"),
                    icon: AppIcon.mail.systemName,
                    keyboardType: .emailAddress,
                    textCapitalization: .never
                )
                .disabled(viewModel.isEmailDisabled)
                .opacity(viewModel.isEmailDisabled ? 0.6 : 1)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(String(localized: "registration.gender"))
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey600)

                    AppRadioGroup(
                        selection: $viewModel.gender,
                        options: [
                            RadioOption(value: "male", title: String(localized: "registration.male")),
                            RadioOption(value: "female", title: String(localized: "registration.female")),
                        ]
                    )
                }

                AppPicker(
                    selection: $viewModel.locale,
                    items: [
                        PickerItem(value: "ar", label: String(localized: "registration.arabic")),
                        PickerItem(value: "en", label: String(localized: "registration.english")),
                    ],
                    label: String(localized: "registration.languageTitle")
                )

                AppDatePicker(
                    value: $viewModel.dayOfBirth,
                    label: String(localized: "registration.dateOfBirth"),
                    range: makeDate(year: 1920, month: 1, day: 1)...makeDate(year: 2015, month: 12, day: 31)
                )

                saveButton
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(String(localized: "confirmDetails.save"))
                }
            }
            .font(Typography.body)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(viewModel.validate() ? AppColors.primary : AppColors.grey300)
            .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
        }
        .disabled(!viewModel.validate() || viewModel.isSaving)
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - Actions

    private func save() async {
        guard let userId = authService.currentUser?.uid else { return }

        HapticService.lightImpact()

        do {
            try await viewModel.save(userId: userId, userDocumentService: userDocumentService)
            toastManager.show(.success, message: String(localized: "confirmDetails.saved"))
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
