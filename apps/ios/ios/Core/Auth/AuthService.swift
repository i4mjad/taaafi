import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

/// Firebase Authentication service with Google/Apple/Email sign-in
/// Ported from: apps/mobile/lib/features/authentication/application/auth_service.dart
@Observable
@MainActor
final class AuthService {

    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = true

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var activeAppleSignInController: ASAuthorizationController?

    // Injected dependencies (set after init via configure)
    private weak var analytics: AnalyticsFacade?
    private weak var errorLogger: ErrorLogger?

    init() {
        setupAuthStateListener()
    }

    /// Configure with dependencies (called from iosApp after all services are created)
    func configure(analytics: AnalyticsFacade, errorLogger: ErrorLogger) {
        self.analytics = analytics
        self.errorLogger = errorLogger
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.currentUser = user
                self.isLoading = false

                if let user {
                    self.analytics?.identifyUser(user.uid)
                } else {
                    self.analytics?.resetUser()
                }
            }
        }
    }

    // MARK: - Email Auth

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            analytics?.trackUserLogin()
        } catch let error as NSError {
            let code = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String ?? error.localizedDescription
            throw AuthError.from(firebaseCode: code)
        }
    }

    func signUpWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = result.user

            // Send email verification
            if let user = result.user, !user.isEmailVerified {
                try? await user.sendEmailVerification()
            }

            analytics?.trackUserSignup()
        } catch let error as NSError {
            let code = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String ?? error.localizedDescription
            throw AuthError.from(firebaseCode: code)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.unknown("No root view controller found")
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.unknown("Missing Google ID token")
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user
            analytics?.trackUserLogin()
        } catch let error as GIDSignInError where error.code == .canceled {
            // User cancelled — not an error
            return
        } catch let error as NSError {
            errorLogger?.logException(error)
            let code = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String ?? error.localizedDescription
            throw AuthError.from(firebaseCode: code)
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let result = try await performAppleSignIn(request: request)

        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.unknown("Unable to get Apple ID token")
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user
            analytics?.trackUserLogin()
        } catch let error as NSError {
            errorLogger?.logException(error)
            let code = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String ?? error.localizedDescription
            throw AuthError.from(firebaseCode: code)
        }
    }

    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate(continuation: continuation)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate
            // Keep controller + delegate alive by storing on self until completion completes
            self.activeAppleSignInController = controller
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            controller.performRequests()
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            analytics?.trackUserLogout()
        } catch {
            errorLogger?.logException(error)
            throw error
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            let code = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String ?? error.localizedDescription
            throw AuthError.from(firebaseCode: code)
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }

        do {
            try await user.delete()
            currentUser = nil
            analytics?.trackUserDeleteAccount()
        } catch let error as NSError {
            errorLogger?.logException(error)
            let code = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String ?? error.localizedDescription
            throw AuthError.from(firebaseCode: code)
        }
    }

    // MARK: - Helpers

    /// Get the auth provider for the current user
    var currentProvider: AuthProvider? {
        guard let providerData = currentUser?.providerData.first else { return nil }
        return AuthProvider(rawValue: providerData.providerID)
    }

    // MARK: - Apple Sign-In Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign-In Delegate

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
