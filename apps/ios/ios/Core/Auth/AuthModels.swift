import Foundation

/// Auth provider types supported by the app
enum AuthProvider: String {
    case email = "password"
    case google = "google.com"
    case apple = "apple.com"
}

/// Result of an authentication operation
enum AuthResult {
    case success
    case cancelled
    case needsAccountCompletion
    case failure(AuthError)
}

/// Authentication errors
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case tooManyRequests
    case userDisabled
    case networkError
    case requiresRecentLogin
    case accountExistsWithDifferentCredential
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "The email address is invalid."
        case .wrongPassword: return "The password is incorrect."
        case .userNotFound: return "No account found with this email."
        case .emailAlreadyInUse: return "An account already exists with this email."
        case .weakPassword: return "The password is too weak."
        case .tooManyRequests: return "Too many attempts. Please try again later."
        case .userDisabled: return "This account has been disabled."
        case .networkError: return "Network error. Please check your connection."
        case .requiresRecentLogin: return "Please sign in again to complete this action."
        case .accountExistsWithDifferentCredential: return "An account already exists with a different sign-in method."
        case .unknown(let message): return message
        }
    }

    static func from(firebaseCode: String) -> AuthError {
        switch firebaseCode {
        case "ERROR_INVALID_EMAIL", "invalid-email": return .invalidEmail
        case "ERROR_WRONG_PASSWORD", "wrong-password", "invalid-credential": return .wrongPassword
        case "ERROR_USER_NOT_FOUND", "user-not-found": return .userNotFound
        case "ERROR_EMAIL_ALREADY_IN_USE", "email-already-in-use": return .emailAlreadyInUse
        case "ERROR_WEAK_PASSWORD", "weak-password": return .weakPassword
        case "ERROR_TOO_MANY_REQUESTS", "too-many-requests": return .tooManyRequests
        case "ERROR_USER_DISABLED", "user-disabled": return .userDisabled
        case "ERROR_NETWORK_REQUEST_FAILED", "network-request-failed": return .networkError
        case "requires-recent-login": return .requiresRecentLogin
        case "account-exists-with-different-credential": return .accountExistsWithDifferentCredential
        default: return .unknown(firebaseCode)
        }
    }
}
