import SwiftUI
import FirebaseAuth

/// Screen for email verification with auto-check and change email flow
struct ConfirmUserEmailScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var viewModel = ConfirmEmailViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                if viewModel.currentStep == 0 {
                    verifyStep
                } else {
                    changeEmailStep
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xxl)
            .background(AppColors.background)
            .navigationTitle(String(localized: "confirmEmail.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                viewModel.startAutoCheck(authService: authService)
            }
            .onDisappear {
                viewModel.cancelTimers()
            }
        }
    }

    // MARK: - Step 0: Verify Email

    private var verifyStep: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: AppIcon.mail.systemName)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)

            Text(String(localized: "confirmEmail.description"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            Text(authService.currentUser?.email ?? "")
                .font(Typography.body)
                .fontWeight(.semibold)

            if viewModel.isVerified {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: AppIcon.checkCircle.systemName)
                        .foregroundStyle(AppColors.success)
                    Text(String(localized: "confirmEmail.verified"))
                        .font(Typography.body)
                        .foregroundStyle(AppColors.success)
                }
            } else {
                // Check verification button
                Button {
                    Task { await viewModel.checkVerificationNow(authService: authService) }
                } label: {
                    Group {
                        if viewModel.isChecking {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(String(localized: "confirmEmail.checkVerification"))
                        }
                    }
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
                }

                // Resend button
                Button {
                    Task { await viewModel.resendVerification(authService: authService) }
                } label: {
                    if viewModel.resendCooldown > 0 {
                        Text(String(localized: "registration.resendIn \(viewModel.resendCooldown)"))
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.grey400)
                    } else {
                        Text(String(localized: "confirmEmail.resend"))
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .disabled(viewModel.resendCooldown > 0)

                // Change email link
                Button {
                    viewModel.switchToChangeEmail()
                } label: {
                    Text(String(localized: "confirmEmail.changeEmail"))
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey500)
                        .underline()
                }
            }

            // Sign out button
            Button {
                try? authService.signOut()
            } label: {
                Text(String(localized: "common.signOut"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.error)
            }
        }
    }

    // MARK: - Step 1: Change Email

    private var changeEmailStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "confirmEmail.changeEmailTitle"))
                .font(Typography.h5)

            Text(String(localized: "confirmEmail.changeEmailDescription"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            AppTextField(
                text: $viewModel.newEmail,
                label: String(localized: "confirmEmail.newEmail"),
                icon: AppIcon.mail.systemName,
                keyboardType: .emailAddress,
                textCapitalization: .never
            )

            if viewModel.isEmailChangeInProgress {
                VStack(spacing: Spacing.sm) {
                    Text(String(localized: "confirmEmail.emailChangeSent"))
                        .font(Typography.body)
                        .foregroundStyle(AppColors.success)

                    Text(String(localized: "confirmEmail.logoutIn \(viewModel.logoutCountdown)"))
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey500)
                }
            } else {
                Button {
                    Task { await updateEmail() }
                } label: {
                    Text(String(localized: "confirmEmail.updateEmail"))
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(viewModel.newEmail.isEmpty ? AppColors.grey300 : AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
                }
                .disabled(viewModel.newEmail.isEmpty)
            }

            Button {
                viewModel.switchToVerify()
            } label: {
                Text(String(localized: "registration.back"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
            }
        }
    }

    // MARK: - Actions

    private func updateEmail() async {
        HapticService.lightImpact()
        do {
            try await viewModel.updateEmail(authService: authService)
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }
}
