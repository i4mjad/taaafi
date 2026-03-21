import SwiftUI
import FirebaseAuth

struct UpdateProfileSheet: View {
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: UpdateProfileViewModel?
    @State private var name = ""
    @State private var dayOfBirth = Date()
    @State private var language = "ar"
    @State private var showConfirmation = false

    @State private var originalName = ""
    @State private var originalDayOfBirth = Date()
    @State private var originalLanguage = "ar"

    private var userDocument: UserDocument? { userDocumentService.userDocument }

    private static let dobRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let min = calendar.date(from: DateComponents(year: 1950, month: 1, day: 1))!
        let max = calendar.date(from: DateComponents(year: 2012, month: 12, day: 31))!
        return min...max
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    nameField
                } header: {
                    Text(Strings.Profile.name)
                        .font(Typography.caption)
                }

                Section {
                    emailField
                } header: {
                    Text(Strings.Profile.email)
                        .font(Typography.caption)
                }

                Section {
                    dobField
                } header: {
                    Text(Strings.Profile.dateOfBirth)
                        .font(Typography.caption)
                }

                Section {
                    languageField
                } header: {
                    Text(Strings.Profile.language)
                        .font(Typography.caption)
                }
            }
            .navigationTitle(Strings.Profile.updateProfile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(Strings.Common.cancel)
                            .font(Typography.body)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showConfirmation = true
                    } label: {
                        Text(Strings.Profile.saveChanges)
                            .font(Typography.body)
                    }
                    .disabled(viewModel?.isValid != true || viewModel?.isSaving == true)
                }
            }
        }
        .task {
            guard let uid = authService.currentUser?.uid else { return }
            let vm = UpdateProfileViewModel(
                userDocument: userDocument,
                userId: uid,
                userDocumentService: userDocumentService
            )
            viewModel = vm
            name = vm.name
            dayOfBirth = vm.dayOfBirth ?? Date()
            language = vm.language
            originalName = vm.name
            originalDayOfBirth = vm.dayOfBirth ?? Date()
            originalLanguage = vm.language
        }
        .sheet(isPresented: $showConfirmation) {
            ProfileChangesConfirmationSheet(
                originalName: originalName,
                newName: name,
                originalDayOfBirth: originalDayOfBirth,
                newDayOfBirth: dayOfBirth,
                originalLanguage: originalLanguage,
                newLanguage: language,
                onConfirm: { Task { await handleSave() } }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Fields

    private var nameField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: AppIcon.person.systemName)
                .foregroundStyle(AppColors.grey900)
            TextField(Strings.Profile.name, text: $name)
                .font(Typography.body)
        }
        .onChange(of: name) { _, newValue in
            viewModel?.name = newValue
        }
    }

    private var emailField: some View {
        Text(authService.currentUser?.email ?? userDocument?.email ?? "")
            .font(Typography.body)
            .foregroundStyle(.secondary)
    }

    private var dobField: some View {
        DatePicker(
            Strings.Profile.dateOfBirth,
            selection: $dayOfBirth,
            in: Self.dobRange,
            displayedComponents: .date
        )
        .onChange(of: dayOfBirth) { _, newValue in
            viewModel?.dayOfBirth = newValue
        }
        .datePickerStyle(.compact)
        .labelsHidden()
    }

private var languageField: some View {
        Picker(Strings.Profile.language, selection: $language) {
            Text(Strings.Profile.arabic).tag("ar")
            Text(Strings.Profile.english).tag("en")
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: language) { _, newValue in
            viewModel?.language = newValue
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
