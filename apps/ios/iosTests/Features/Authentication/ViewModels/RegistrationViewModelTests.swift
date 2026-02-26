import Testing
import Foundation
@testable import ios

@Suite("RegistrationViewModel")
@MainActor
struct RegistrationViewModelTests {

    // MARK: - Step Configuration

    @Test("Email user has 7 total steps")
    func emailUserTotalSteps() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(vm.totalSteps == 7)
    }

    @Test("OAuth user has 5 total steps")
    func oauthUserTotalSteps() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        #expect(vm.totalSteps == 5)
    }

    @Test("Email user first step is credentials")
    func emailFirstStepIsCredentials() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(vm.currentStepType == .credentials)
    }

    @Test("OAuth user first step is profile (skips credentials)")
    func oauthFirstStepIsProfile() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        #expect(vm.currentStepType == .profile)
    }

    @Test("OAuth user does not have email verification step")
    func oauthNoEmailVerification() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        let oauthSteps: [RegistrationStep] = [.profile, .language, .recoveryDate, .referral, .terms]
        for i in 0..<vm.totalSteps {
            vm.currentStep = i
            #expect(vm.currentStepType != .emailVerification)
            #expect(vm.currentStepType == oauthSteps[i])
        }
    }

    // MARK: - Step Navigation

    @Test("nextStep increments currentStep")
    func nextStepIncrements() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(vm.currentStep == 0)
        vm.nextStep()
        #expect(vm.currentStep == 1)
    }

    @Test("nextStep does not exceed totalSteps - 1")
    func nextStepBound() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        for _ in 0..<10 {
            vm.nextStep()
        }
        #expect(vm.currentStep == vm.totalSteps - 1)
    }

    @Test("previousStep decrements currentStep")
    func previousStepDecrements() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.currentStep = 3
        vm.previousStep()
        #expect(vm.currentStep == 2)
    }

    @Test("previousStep does not go below 0")
    func previousStepBound() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.previousStep()
        #expect(vm.currentStep == 0)
    }

    @Test("isFirstStep returns true when on step 0")
    func isFirstStep() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(vm.isFirstStep)
    }

    @Test("isLastStep returns true when on final step")
    func isLastStep() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        vm.currentStep = vm.totalSteps - 1
        #expect(vm.isLastStep)
    }

    // MARK: - Email Validation

    @Test("Valid email passes validation")
    func validEmail() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(vm.isValidEmail("test@example.com"))
        #expect(vm.isValidEmail("user.name+tag@domain.co.uk"))
        #expect(vm.isValidEmail("a@b.cd"))
    }

    @Test("Invalid email fails validation")
    func invalidEmail() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(!vm.isValidEmail(""))
        #expect(!vm.isValidEmail("notanemail"))
        #expect(!vm.isValidEmail("@domain.com"))
        #expect(!vm.isValidEmail("user@"))
        #expect(!vm.isValidEmail("user@.com"))
    }

    // MARK: - Password Validation

    @Test("Valid password passes (8+ chars, digit, special char)")
    func validPassword() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(vm.isValidPassword("Pass1234!"))
        #expect(vm.isValidPassword("abcdefg1@"))
        #expect(vm.isValidPassword("12345678$"))
    }

    @Test("Short password fails")
    func shortPassword() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(!vm.isValidPassword("Ab1!"))
        #expect(!vm.isValidPassword("1234567"))
    }

    @Test("Password without digit fails")
    func passwordNoDigit() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(!vm.isValidPassword("abcdefgh!"))
    }

    @Test("Password without special char fails")
    func passwordNoSpecial() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        #expect(!vm.isValidPassword("abcdefg1"))
    }

    // MARK: - Credentials Step Validation

    @Test("Credentials valid when email, password, and confirm match")
    func credentialsValid() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.email = "test@example.com"
        vm.password = "Pass1234!"
        vm.confirmPassword = "Pass1234!"
        #expect(vm.validateCredentials())
    }

    @Test("Credentials invalid when passwords don't match")
    func credentialsPasswordMismatch() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.email = "test@example.com"
        vm.password = "Pass1234!"
        vm.confirmPassword = "Different1!"
        #expect(!vm.validateCredentials())
    }

    // MARK: - Profile Validation

    @Test("Profile valid with name and DOB before 2015")
    func profileValid() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.displayName = "Test User"
        vm.dayOfBirth = makeDate(year: 2000, month: 6, day: 15)
        #expect(vm.validateProfile())
    }

    @Test("Profile invalid with empty name")
    func profileEmptyName() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.displayName = ""
        vm.dayOfBirth = makeDate(year: 2000, month: 6, day: 15)
        #expect(!vm.validateProfile())
    }

    @Test("Profile invalid with whitespace-only name")
    func profileWhitespaceName() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.displayName = "   "
        vm.dayOfBirth = makeDate(year: 2000, month: 6, day: 15)
        #expect(!vm.validateProfile())
    }

    @Test("Profile invalid with nil DOB")
    func profileNilDob() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.displayName = "Test"
        vm.dayOfBirth = nil
        #expect(!vm.validateProfile())
    }

    @Test("Profile invalid with DOB after 2015-12-31")
    func profileDobTooRecent() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.displayName = "Test"
        vm.dayOfBirth = makeDate(year: 2020, month: 1, day: 1)
        #expect(!vm.validateProfile())
    }

    // MARK: - Recovery Date Validation

    @Test("Recovery date valid when startFromNow is true")
    func recoveryDateStartFromNow() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.startFromNow = true
        #expect(vm.validateRecoveryDate())
    }

    @Test("Recovery date valid when custom date is in valid range")
    func recoveryDateValidCustom() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.startFromNow = false
        vm.recoveryStartDate = makeDate(year: 2023, month: 6, day: 1)
        #expect(vm.validateRecoveryDate())
    }

    @Test("Recovery date invalid when custom date is nil")
    func recoveryDateNilCustom() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.startFromNow = false
        vm.recoveryStartDate = nil
        #expect(!vm.validateRecoveryDate())
    }

    @Test("Recovery date invalid when before 2022-01-01")
    func recoveryDateTooEarly() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.startFromNow = false
        vm.recoveryStartDate = makeDate(year: 2021, month: 12, day: 31)
        #expect(!vm.validateRecoveryDate())
    }

    // MARK: - Terms Validation

    @Test("Terms step invalid when not accepted")
    func termsNotAccepted() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        vm.currentStep = 4 // terms step for OAuth
        vm.acceptedTerms = false
        #expect(!vm.validateCurrentStep())
    }

    @Test("Terms step valid when accepted")
    func termsAccepted() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        vm.currentStep = 4 // terms step for OAuth
        vm.acceptedTerms = true
        #expect(vm.validateCurrentStep())
    }

    // MARK: - Language and Referral always valid

    @Test("Language step always validates")
    func languageAlwaysValid() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        vm.currentStep = 1 // language step for OAuth
        #expect(vm.validateCurrentStep())
    }

    @Test("Referral step always validates")
    func referralAlwaysValid() {
        let vm = RegistrationViewModel(isOAuthUser: true)
        vm.currentStep = 3 // referral step for OAuth
        #expect(vm.validateCurrentStep())
    }

    // MARK: - Error Messages

    @Test("emailError returns nil for empty email")
    func emailErrorEmpty() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.email = ""
        #expect(vm.emailError() == nil)
    }

    @Test("emailError returns message for invalid email")
    func emailErrorInvalid() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.email = "not-valid"
        #expect(vm.emailError() != nil)
    }

    @Test("passwordError returns nil for empty password")
    func passwordErrorEmpty() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.password = ""
        #expect(vm.passwordError() == nil)
    }

    @Test("passwordError returns message for weak password")
    func passwordErrorWeak() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.password = "short"
        #expect(vm.passwordError() != nil)
    }

    @Test("confirmPasswordError returns nil when empty")
    func confirmPasswordErrorEmpty() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.confirmPassword = ""
        #expect(vm.confirmPasswordError() == nil)
    }

    @Test("confirmPasswordError returns message when mismatch")
    func confirmPasswordErrorMismatch() {
        let vm = RegistrationViewModel(isOAuthUser: false)
        vm.password = "Pass1234!"
        vm.confirmPassword = "Different1!"
        #expect(vm.confirmPasswordError() != nil)
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
