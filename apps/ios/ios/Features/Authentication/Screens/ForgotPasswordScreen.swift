import SwiftUI

/// Simple screen for sending a password reset email
struct ForgotPasswordScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Text(String(localized: "auth.forgotPasswordTitle"))
                .font(Typography.h5)

            Text(String(localized: "auth.forgotPasswordDescription"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            AppTextField(
                text: $email,
                label: String(localized: "auth.email"),
                icon: AppIcon.mail.systemName,
                keyboardType: .emailAddress,
                textCapitalization: .never
            )

            Button {
                Task { await sendResetLink() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(String(localized: "auth.sendResetLink"))
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
            .disabled(isLoading)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxl)
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendResetLink() async {
        guard !email.isEmpty else {
            toastManager.show(.info, message: String(localized: "auth.enterEmail"))
            return
        }

        HapticService.lightImpact()
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.resetPassword(email: email)
            toastManager.show(.success, message: String(localized: "auth.resetLinkSent"))
            dismiss()
        } catch let error as AuthError {
            toastManager.show(.error, message: error.localizedDescription)
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }
}
