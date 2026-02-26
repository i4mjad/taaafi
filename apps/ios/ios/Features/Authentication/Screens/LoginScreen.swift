import SwiftUI
import AuthenticationServices

/// Email/password login screen with Google and Apple sign-in options
struct LoginScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(AnalyticsFacade.self) private var analytics

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    avatarSection

                    fieldsSection

                    forgotPasswordLink

                    loginButton

                    divider

                    socialButtons

                    signUpLink
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xxl)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        Circle()
            .fill(AppColors.primary100)
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.primary)
            }
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(spacing: Spacing.md) {
            AppTextField(
                text: $email,
                label: String(localized: "auth.email"),
                icon: AppIcon.mail.systemName,
                keyboardType: .emailAddress,
                textCapitalization: .never
            )

            AppTextField(
                text: $password,
                label: String(localized: "auth.password"),
                isSecure: true
            )
        }
    }

    // MARK: - Forgot Password

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            NavigationLink {
                ForgotPasswordScreen()
            } label: {
                Text(String(localized: "auth.forgotPassword"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.primary)
            }
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            Task { await login() }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(String(localized: "auth.login"))
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
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: Spacing.md) {
            Rectangle()
                .fill(AppColors.grey200)
                .frame(height: 1)
            Text(String(localized: "auth.or"))
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey400)
            Rectangle()
                .fill(AppColors.grey200)
                .frame(height: 1)
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: Spacing.sm) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in
                // Apple sign-in handled via AuthService
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            .onTapGesture {
                HapticService.lightImpact()
                Task { await signInWithApple() }
            }

            Button {
                HapticService.lightImpact()
                Task { await signInWithGoogle() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text(String(localized: "auth.signInWithGoogle"))
                        .font(Typography.body)
                        .fontWeight(.medium)
                }
                .foregroundStyle(AppColors.grey900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10.5, style: .continuous)
                        .stroke(AppColors.grey300, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Sign Up Link

    private var signUpLink: some View {
        HStack(spacing: Spacing.xxs) {
            Text(String(localized: "auth.noAccount"))
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)

            NavigationLink {
                RegistrationStepperScreen(isOAuthUser: false)
            } label: {
                Text(String(localized: "auth.signUp"))
                    .font(Typography.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - Actions

    private func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            toastManager.show(.info, message: String(localized: "auth.fillAllFields"))
            return
        }

        HapticService.lightImpact()
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signInWithEmail(email: email, password: password)
        } catch let error as AuthError {
            toastManager.show(.error, message: error.localizedDescription)
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }

    private func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signInWithGoogle()
        } catch let error as AuthError {
            toastManager.show(.error, message: error.localizedDescription)
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }

    private func signInWithApple() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signInWithApple()
        } catch let error as AuthError {
            toastManager.show(.error, message: error.localizedDescription)
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }
}
