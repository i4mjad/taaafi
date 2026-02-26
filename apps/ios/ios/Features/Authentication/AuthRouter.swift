import SwiftUI
import FirebaseAuth

/// Root router that directs users to the appropriate screen based on auth and document state
struct AuthRouter: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(ToastManager.self) private var toastManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if authService.isLoading {
                loadingView
            } else if !authService.isAuthenticated {
                if hasCompletedOnboarding {
                    LoginScreen()
                } else {
                    OnboardingScreen()
                }
            } else {
                authenticatedContent
            }
        }
    }

    // MARK: - Authenticated Content

    @ViewBuilder
    private var authenticatedContent: some View {
        // Check email verification first for email-based accounts
        if authService.currentProvider == .email,
           authService.currentUser?.isEmailVerified == false {
            ConfirmUserEmailScreen()
        } else {
            switch userDocumentService.accountStatus {
            case .loading:
                loadingView
            case .needCompleteRegistration:
                RegistrationStepperScreen(isOAuthUser: authService.currentProvider != .email)
            case .needConfirmDetails:
                ConfirmUserDetailsScreen()
            case .needEmailVerification:
                ConfirmUserEmailScreen()
            case .pendingDeletion:
                MainTabView()
            case .error:
                errorView
            case .ok:
                MainTabView()
            }
        }
    }

    // MARK: - Support Views

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "common.loading"))
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private var errorView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: AppIcon.alertCircle.systemName)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.error)

            Text(String(localized: "auth.errorTitle"))
                .font(Typography.h4)

            Text(String(localized: "auth.errorMessage"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Button {
                // Force refresh by restarting listener
                if let uid = authService.currentUser?.uid {
                    userDocumentService.startListening(userId: uid)
                }
            } label: {
                Text(String(localized: "common.retry"))
                    .font(Typography.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            }
            .padding(.horizontal, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
