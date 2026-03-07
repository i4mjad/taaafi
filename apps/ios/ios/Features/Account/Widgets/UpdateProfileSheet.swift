import SwiftUI
import FirebaseAuth

struct UpdateProfileSheet: View {
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: UpdateProfileViewModel?
    @State private var showConfirmation = false

    private var userDocument: UserDocument? { userDocumentService.userDocument }

    private static let dobRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let min = calendar.date(from: DateComponents(year: 1950, month: 1, day: 1))!
        let max = calendar.date(from: DateComponents(year: 2012, month: 12, day: 31))!
        return min...max
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    nameField

                    emailField

                    dobField

                    startingDateField

                    roleField

                    genderField

                    languageField
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .background(AppColors.grey50)
            .navigationTitle(Strings.Profile.updateProfile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Profile.saveChanges) {
                        showConfirmation = true
                    }
                    .disabled(viewModel?.isValid != true || viewModel?.isSaving == true)
                }
            }
        }
        .task {
            guard let uid = authService.currentUser?.uid else { return }
            viewModel = UpdateProfileViewModel(
                userDocument: userDocument,
                userId: uid,
                userDocumentService: userDocumentService
            )
        }
        .confirmationSheet(
            isPresented: $showConfirmation,
            icon: AppIcon.pencil.systemName,
            title: Strings.Profile.confirmUpdateTitle,
            message: Strings.Profile.confirmUpdateMessage,
            confirmLabel: Strings.Profile.saveChanges,
            onResult: { confirmed in
                if confirmed { Task { await handleSave() } }
            }
        )
    }

    // MARK: - Fields

    private var nameField: some View {
        AppTextField(
            text: Binding(
                get: { viewModel?.name ?? "" },
                set: { viewModel?.name = $0 }
            ),
            label: Strings.Profile.name,
            icon: AppIcon.person.systemName
        )
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.email)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            Text(authService.currentUser?.email ?? userDocument?.email ?? "")
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(AppColors.grey100)
                .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
        }
    }

    private var dobField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.dateOfBirth)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel?.dayOfBirth ?? Date() },
                    set: { viewModel?.dayOfBirth = $0 }
                ),
                in: Self.dobRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }

    private var startingDateField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.startingDate)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            Text(userDocument?.userFirstDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(AppColors.grey100)
                .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
        }
    }

    private var roleField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.role)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            Text(userDocument?.role ?? "user")
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(AppColors.grey100)
                .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
        }
    }

    private var genderField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.gender)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            Text(userDocument?.gender ?? "")
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(AppColors.grey100)
                .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
        }
    }

    private var languageField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.language)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            Picker("", selection: Binding(
                get: { viewModel?.language ?? "ar" },
                set: { viewModel?.language = $0 }
            )) {
                Text(Strings.Profile.arabic).tag("ar")
                Text(Strings.Profile.english).tag("en")
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Actions

    private func handleSave() async {
        guard let result = await viewModel?.save(), result else {
            toastManager.show(.error, message: Strings.Account.error)
            return
        }
        toastManager.show(.success, message: Strings.Profile.profileUpdated)
        dismiss()
    }
}
