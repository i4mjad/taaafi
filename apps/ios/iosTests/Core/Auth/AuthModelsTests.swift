import Testing
@testable import ios

@Suite("AuthError")
struct AuthErrorTests {

    // MARK: - from(firebaseCode:) mapping

    @Test("Maps legacy ERROR_INVALID_EMAIL to invalidEmail")
    func legacyInvalidEmail() {
        #expect(AuthError.from(firebaseCode: "ERROR_INVALID_EMAIL") == .invalidEmail)
    }

    @Test("Maps modern invalid-email to invalidEmail")
    func modernInvalidEmail() {
        #expect(AuthError.from(firebaseCode: "invalid-email") == .invalidEmail)
    }

    @Test("Maps ERROR_WRONG_PASSWORD to wrongPassword")
    func legacyWrongPassword() {
        #expect(AuthError.from(firebaseCode: "ERROR_WRONG_PASSWORD") == .wrongPassword)
    }

    @Test("Maps wrong-password to wrongPassword")
    func modernWrongPassword() {
        #expect(AuthError.from(firebaseCode: "wrong-password") == .wrongPassword)
    }

    @Test("Maps invalid-credential to wrongPassword")
    func invalidCredential() {
        #expect(AuthError.from(firebaseCode: "invalid-credential") == .wrongPassword)
    }

    @Test("Maps user-not-found codes")
    func userNotFound() {
        #expect(AuthError.from(firebaseCode: "ERROR_USER_NOT_FOUND") == .userNotFound)
        #expect(AuthError.from(firebaseCode: "user-not-found") == .userNotFound)
    }

    @Test("Maps email-already-in-use codes")
    func emailAlreadyInUse() {
        #expect(AuthError.from(firebaseCode: "ERROR_EMAIL_ALREADY_IN_USE") == .emailAlreadyInUse)
        #expect(AuthError.from(firebaseCode: "email-already-in-use") == .emailAlreadyInUse)
    }

    @Test("Maps weak-password codes")
    func weakPassword() {
        #expect(AuthError.from(firebaseCode: "ERROR_WEAK_PASSWORD") == .weakPassword)
        #expect(AuthError.from(firebaseCode: "weak-password") == .weakPassword)
    }

    @Test("Maps too-many-requests codes")
    func tooManyRequests() {
        #expect(AuthError.from(firebaseCode: "ERROR_TOO_MANY_REQUESTS") == .tooManyRequests)
        #expect(AuthError.from(firebaseCode: "too-many-requests") == .tooManyRequests)
    }

    @Test("Maps user-disabled codes")
    func userDisabled() {
        #expect(AuthError.from(firebaseCode: "ERROR_USER_DISABLED") == .userDisabled)
        #expect(AuthError.from(firebaseCode: "user-disabled") == .userDisabled)
    }

    @Test("Maps network-request-failed codes")
    func networkError() {
        #expect(AuthError.from(firebaseCode: "ERROR_NETWORK_REQUEST_FAILED") == .networkError)
        #expect(AuthError.from(firebaseCode: "network-request-failed") == .networkError)
    }

    @Test("Maps requires-recent-login")
    func requiresRecentLogin() {
        #expect(AuthError.from(firebaseCode: "requires-recent-login") == .requiresRecentLogin)
    }

    @Test("Maps account-exists-with-different-credential")
    func accountExistsDifferentCredential() {
        #expect(AuthError.from(firebaseCode: "account-exists-with-different-credential") == .accountExistsWithDifferentCredential)
    }

    @Test("Unknown codes produce .unknown with the original string")
    func unknownCode() {
        let result = AuthError.from(firebaseCode: "some-new-error")
        if case .unknown(let message) = result {
            #expect(message == "some-new-error")
        } else {
            Issue.record("Expected .unknown, got \(result)")
        }
    }

    // MARK: - errorDescription

    @Test("Each error case returns a non-nil description")
    func allDescriptionsNonNil() {
        let cases: [AuthError] = [
            .invalidEmail, .wrongPassword, .userNotFound, .emailAlreadyInUse,
            .weakPassword, .tooManyRequests, .userDisabled, .networkError,
            .requiresRecentLogin, .accountExistsWithDifferentCredential, .unknown("test")
        ]
        for error in cases {
            #expect(error.errorDescription != nil, "errorDescription should not be nil for \(error)")
        }
    }

    @Test(".unknown passes through the original message")
    func unknownDescription() {
        let error = AuthError.unknown("custom message")
        #expect(error.errorDescription == "custom message")
    }
}

@Suite("AuthProvider")
struct AuthProviderTests {

    @Test("Raw values match Firebase provider IDs")
    func rawValues() {
        #expect(AuthProvider.email.rawValue == "password")
        #expect(AuthProvider.google.rawValue == "google.com")
        #expect(AuthProvider.apple.rawValue == "apple.com")
    }

    @Test("Round-trip from rawValue")
    func roundTrip() {
        #expect(AuthProvider(rawValue: "password") == .email)
        #expect(AuthProvider(rawValue: "google.com") == .google)
        #expect(AuthProvider(rawValue: "apple.com") == .apple)
        #expect(AuthProvider(rawValue: "facebook.com") == nil)
    }
}
