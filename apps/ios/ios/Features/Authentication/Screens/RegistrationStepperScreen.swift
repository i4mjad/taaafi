import SwiftUI

/// Multi-step registration screen with step indicator and navigation
struct RegistrationStepperScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(DeviceTrackingService.self) private var deviceTrackingService
    @Environment(ToastManager.self) private var toastManager
    @Environment(AnalyticsFacade.self) private var analytics

    @State private var viewModel: RegistrationViewModel
    @State private var showPaywall = false

    init(isOAuthUser: Bool) {
        _viewModel = State(initialValue: RegistrationViewModel(isOAuthUser: isOAuthUser))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator

                ScrollView {
                    stepContent
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.xl)
                }

                navigationButtons
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showPaywall) {
                PaywallScreen()
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= viewModel.currentStep ? AppColors.primary : AppColors.grey200)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStepType {
        case .credentials:
            credentialsStep
        case .profile:
            profileStep
        case .language:
            languageStep
        case .recoveryDate:
            recoveryDateStep
        case .emailVerification:
            emailVerificationStep
        case .referral:
            referralStep
        case .terms:
            termsStep
        }
    }

    // MARK: - Step 1: Credentials

    private var credentialsStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.credentialsTitle"))
                .font(Typography.h5)

            AppTextField(
                text: $viewModel.email,
                label: String(localized: "auth.email"),
                icon: AppIcon.mail.systemName,
                validator: { _ in viewModel.emailError() },
                keyboardType: .emailAddress,
                textCapitalization: .never
            )

            AppTextField(
                text: $viewModel.password,
                label: String(localized: "auth.password"),
                isSecure: true,
                validator: { _ in viewModel.passwordError() }
            )

            AppTextField(
                text: $viewModel.confirmPassword,
                label: String(localized: "registration.confirmPassword"),
                isSecure: true,
                validator: { _ in viewModel.confirmPasswordError() }
            )
        }
    }

    // MARK: - Step 2: Profile

    private var profileStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.profileTitle"))
                .font(Typography.h5)

            AppTextField(
                text: $viewModel.displayName,
                label: String(localized: "registration.name"),
                maxLength: 50
            )

            AppDatePicker(
                value: $viewModel.dayOfBirth,
                label: String(localized: "registration.dateOfBirth"),
                range: makeDate(year: 1920, month: 1, day: 1)...makeDate(year: 2015, month: 12, day: 31)
            )

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
        }
    }

    // MARK: - Step 3: Language

    private var languageStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.languageTitle"))
                .font(Typography.h5)

            Text(String(localized: "registration.languageDescription"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            AppRadioGroup(
                selection: $viewModel.locale,
                options: [
                    RadioOption(value: "ar", title: String(localized: "registration.arabic")),
                    RadioOption(value: "en", title: String(localized: "registration.english")),
                ]
            )
        }
    }

    // MARK: - Step 4: Recovery Date

    private var recoveryDateStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.recoveryDateTitle"))
                .font(Typography.h5)

            Text(String(localized: "registration.recoveryDateDescription"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            AppRadioGroup(
                selection: $viewModel.startFromNow,
                options: [
                    RadioOption(value: true, title: String(localized: "registration.startFromNow")),
                    RadioOption(value: false, title: String(localized: "registration.chooseDate")),
                ]
            )

            if !viewModel.startFromNow {
                AppDatePicker(
                    value: $viewModel.recoveryStartDate,
                    label: String(localized: "registration.recoveryStartDate"),
                    range: makeDate(year: 2022, month: 1, day: 1)...Date()
                )
            }
        }
    }

    // MARK: - Step 5: Email Verification

    private var emailVerificationStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.emailVerificationTitle"))
                .font(Typography.h5)

            Image(systemName: AppIcon.mail.systemName)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)

            Text(String(localized: "registration.emailVerificationDescription"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            Text(viewModel.email)
                .font(Typography.body)
                .fontWeight(.semibold)

            if viewModel.isEmailVerified {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: AppIcon.checkCircle.systemName)
                        .foregroundStyle(AppColors.success)
                    Text(String(localized: "registration.emailVerified"))
                        .font(Typography.body)
                        .foregroundStyle(AppColors.success)
                }
            } else {
                Button {
                    Task { await viewModel.resendVerificationEmail(authService: authService) }
                } label: {
                    if viewModel.resendCooldown > 0 {
                        Text(String(localized: "registration.resendIn \(viewModel.resendCooldown)"))
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.grey400)
                    } else {
                        Text(String(localized: "registration.resendEmail"))
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .disabled(viewModel.resendCooldown > 0)
            }
        }
        .task {
            viewModel.startVerificationCheck(authService: authService)
        }
        .onDisappear {
            viewModel.stopVerificationCheck()
        }
    }

    // MARK: - Step 6: Referral

    private var referralStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.referralTitle"))
                .font(Typography.h5)

            Text(String(localized: "registration.referralDescription"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)

            AppTextField(
                text: $viewModel.referralCode,
                label: String(localized: "registration.referralCode"),
                maxLength: 20,
                textCapitalization: .characters
            )

            Button {
                HapticService.lightImpact()
                viewModel.nextStep()
            } label: {
                Text(String(localized: "registration.skip"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
            }
        }
    }

    // MARK: - Step 7: Terms

    private var termsStep: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "registration.termsTitle"))
                .font(Typography.h5)

            AppCheckboxRow(
                isChecked: $viewModel.acceptedTerms,
                title: String(localized: "registration.acceptTerms")
            )

            // Terms link
            Button {
                // Open terms URL
            } label: {
                Text(String(localized: "registration.viewTerms"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.primary)
                    .underline()
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: Spacing.md) {
            if !viewModel.isFirstStep {
                Button {
                    HapticService.lightImpact()
                    withAnimation { viewModel.previousStep() }
                } label: {
                    Text(String(localized: "registration.back"))
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppColors.grey100)
                        .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
                }
            }

            Button {
                Task { await handleNext() }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.isLastStep
                             ? String(localized: "registration.submit")
                             : String(localized: "registration.next"))
                    }
                }
                .font(Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(viewModel.validateCurrentStep() ? AppColors.primary : AppColors.grey300)
                .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            }
            .disabled(!viewModel.validateCurrentStep() || viewModel.isSubmitting)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Actions

    private func handleNext() async {
        HapticService.lightImpact()

        if viewModel.isLastStep {
            await submitRegistration()
        } else {
            // For email users on credentials step, create the account first
            if viewModel.currentStepType == .credentials {
                await createEmailAccount()
            } else {
                withAnimation { viewModel.nextStep() }
            }
        }
    }

    private func createEmailAccount() async {
        viewModel.isSubmitting = true
        defer { viewModel.isSubmitting = false }

        do {
            try await authService.signUpWithEmail(email: viewModel.email, password: viewModel.password)
            withAnimation { viewModel.nextStep() }
        } catch let error as AuthError {
            toastManager.show(.error, message: error.localizedDescription)
        } catch {
            toastManager.show(.error, message: error.localizedDescription)
        }
    }

    private func submitRegistration() async {
        do {
            try await viewModel.submitRegistration(
                authService: authService,
                userDocumentService: userDocumentService,
                deviceTrackingService: deviceTrackingService,
                analytics: analytics
            )
            showPaywall = true
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
