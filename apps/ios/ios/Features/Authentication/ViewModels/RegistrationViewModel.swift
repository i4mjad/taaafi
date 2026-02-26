import Foundation
import FirebaseAuth

/// Manages registration flow state, validation, and step navigation
@Observable
@MainActor
final class RegistrationViewModel {

    // MARK: - Step Management

    var currentStep = 0
    let isOAuthUser: Bool

    /// Total steps: 7 for email users, 5 for OAuth (skip steps 0 and 4)
    var totalSteps: Int { isOAuthUser ? 5 : 7 }

    /// The visible step index (0-based for display)
    var visibleStepIndex: Int {
        if isOAuthUser {
            // OAuth skips step 0 (credentials) and step 4 (email verification)
            return currentStep
        }
        return currentStep
    }

    // MARK: - Step 1: Credentials (email users only)

    var email = ""
    var password = ""
    var confirmPassword = ""

    // MARK: - Step 2: Profile

    var displayName = ""
    var dayOfBirth: Date?
    var gender = "male"

    // MARK: - Step 3: Language

    var locale = "en"

    // MARK: - Step 4: Recovery Start Date

    var startFromNow = true
    var recoveryStartDate: Date?

    // MARK: - Step 5: Email Verification (email users only)

    var isEmailVerified = false
    var resendCooldown = 0

    // MARK: - Step 6: Referral Code

    var referralCode = ""

    // MARK: - Step 7: Terms

    var acceptedTerms = false

    // MARK: - State

    var isSubmitting = false
    nonisolated(unsafe) var verificationCheckTimer: Task<Void, Never>?
    nonisolated(unsafe) var resendCooldownTimer: Task<Void, Never>?

    // MARK: - Init

    init(isOAuthUser: Bool) {
        self.isOAuthUser = isOAuthUser
    }

    deinit {
        verificationCheckTimer?.cancel()
        resendCooldownTimer?.cancel()
    }

    // MARK: - Step Navigation

    /// Maps logical step index to step type for display
    var currentStepType: RegistrationStep {
        if isOAuthUser {
            return oauthSteps[currentStep]
        }
        return emailSteps[currentStep]
    }

    private let emailSteps: [RegistrationStep] = [
        .credentials, .profile, .language, .recoveryDate, .emailVerification, .referral, .terms
    ]

    private let oauthSteps: [RegistrationStep] = [
        .profile, .language, .recoveryDate, .referral, .terms
    ]

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    var isFirstStep: Bool { currentStep == 0 }
    var isLastStep: Bool { currentStep == totalSteps - 1 }

    // MARK: - Validation

    func validateCurrentStep() -> Bool {
        switch currentStepType {
        case .credentials:
            return validateCredentials()
        case .profile:
            return validateProfile()
        case .language:
            return true
        case .recoveryDate:
            return validateRecoveryDate()
        case .emailVerification:
            return isEmailVerified
        case .referral:
            return true
        case .terms:
            return acceptedTerms
        }
    }

    func validateCredentials() -> Bool {
        isValidEmail(email) && isValidPassword(password) && password == confirmPassword
    }

    func validateProfile() -> Bool {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let dob = dayOfBirth else { return false }

        let maxDate = makeDate(year: 2015, month: 12, day: 31)
        return dob <= maxDate
    }

    func validateRecoveryDate() -> Bool {
        if startFromNow { return true }
        guard let date = recoveryStartDate else { return false }

        let minDate = makeDate(year: 2022, month: 1, day: 1)
        return date >= minDate && date <= Date()
    }

    // MARK: - Field Validators

    static let emailRegex = /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$/

    func isValidEmail(_ email: String) -> Bool {
        (try? Self.emailRegex.wholeMatch(in: email)) != nil
    }

    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        let hasDigit = password.contains(where: \.isNumber)
        let hasSpecial = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        return hasDigit && hasSpecial
    }

    // MARK: - Email Validation Error Messages

    func emailError() -> String? {
        guard !email.isEmpty else { return nil }
        return isValidEmail(email) ? nil : String(localized: "registration.invalidEmail")
    }

    func passwordError() -> String? {
        guard !password.isEmpty else { return nil }
        return isValidPassword(password) ? nil : String(localized: "registration.weakPassword")
    }

    func confirmPasswordError() -> String? {
        guard !confirmPassword.isEmpty else { return nil }
        return password == confirmPassword ? nil : String(localized: "registration.passwordMismatch")
    }

    // MARK: - Submit

    func submitRegistration(
        authService: AuthService,
        userDocumentService: UserDocumentService,
        deviceTrackingService: DeviceTrackingService,
        analytics: AnalyticsFacade
    ) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        // For email users, create the Firebase Auth account first
        if !isOAuthUser {
            try await authService.signUpWithEmail(email: email, password: password)
        }

        guard let userId = authService.currentUser?.uid else {
            throw RegistrationError.noAuthUser
        }

        // Build the Firestore user document
        let userEmail = isOAuthUser ? (authService.currentUser?.email ?? email) : email
        let firstDate = startFromNow ? Date() : (recoveryStartDate ?? Date())

        let doc = UserDocument(
            devicesIds: [deviceTrackingService.deviceId],
            displayName: displayName,
            email: userEmail,
            gender: gender,
            locale: locale,
            dayOfBirth: dayOfBirth,
            userFirstDate: firstDate,
            role: "user",
            userRelapses: [],
            userMasturbatingWithoutWatching: [],
            userWatchingWithoutMasturbating: [],
            isPlusUser: false,
            isRequestedToBeDeleted: false,
            hasCheckedForDataLoss: false
        )

        try await userDocumentService.createUserDocument(doc, userId: userId)
        try await deviceTrackingService.updateUserDeviceIds(userId: userId)

        analytics.trackUserSignup()
    }

    // MARK: - Email Verification

    func startVerificationCheck(authService: AuthService) {
        verificationCheckTimer?.cancel()
        verificationCheckTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }

                try? await authService.currentUser?.reload()
                if authService.currentUser?.isEmailVerified == true {
                    self?.isEmailVerified = true
                    return
                }
            }
        }
    }

    func stopVerificationCheck() {
        verificationCheckTimer?.cancel()
        verificationCheckTimer = nil
    }

    func resendVerificationEmail(authService: AuthService) async {
        guard resendCooldown == 0 else { return }
        try? await authService.currentUser?.sendEmailVerification()
        startResendCooldown()
    }

    func startResendCooldown() {
        resendCooldown = 60
        resendCooldownTimer?.cancel()
        resendCooldownTimer = Task { [weak self] in
            while let self, self.resendCooldown > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.resendCooldown -= 1
            }
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

// MARK: - Supporting Types

enum RegistrationStep {
    case credentials
    case profile
    case language
    case recoveryDate
    case emailVerification
    case referral
    case terms
}

enum RegistrationError: LocalizedError {
    case noAuthUser

    var errorDescription: String? {
        switch self {
        case .noAuthUser:
            return "No authenticated user found after registration."
        }
    }
}
