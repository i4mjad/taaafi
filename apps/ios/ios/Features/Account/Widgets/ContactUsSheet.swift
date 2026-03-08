import SwiftUI
import FirebaseAuth

struct ContactUsSheet: View {
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ContactUsViewModel?
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text(Strings.Profile.contactUsDescription)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AppTextArea(
                    text: $messageText,
                    label: Strings.Profile.messageLabel,
                    maxLength: 220
                )
                .onChange(of: messageText) { _, newValue in
                    viewModel?.messageText = newValue
                }

                Spacer()

                submitButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .navigationTitle(Strings.Profile.contactUsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
        }
        .task {
            guard let user = authService.currentUser else { return }
            viewModel = ContactUsViewModel(
                firestoreService: firestoreService,
                userId: user.uid,
                userEmail: user.email ?? ""
            )
        }
    }

    private var submitButton: some View {
        Button {
            Task { await handleSubmit() }
        } label: {
            HStack(spacing: Spacing.xs) {
                if viewModel?.isSubmitting == true {
                    AppSpinner(tint: .white)
                } else {
                    Image(systemName: AppIcon.paperplane.systemName)
                    Text(Strings.Profile.sendMessage)
                }
            }
            .font(Typography.body)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(viewModel?.isValid == true ? AppColors.primary600 : AppColors.grey300)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(viewModel?.isValid != true || viewModel?.isSubmitting == true)
        .accessibilityLabel(Strings.Profile.sendMessage)
    }

    private func handleSubmit() async {
        guard let result = await viewModel?.submit(), result else {
            toastManager.show(.error, message: Strings.Account.error)
            return
        }
        toastManager.show(.success, message: Strings.Profile.messageSent)
        dismiss()
    }
}
