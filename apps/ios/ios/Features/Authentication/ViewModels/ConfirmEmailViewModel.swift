import Foundation
import FirebaseAuth

/// ViewModel for email verification and email change flow
@Observable
@MainActor
final class ConfirmEmailViewModel {

    /// Step 0 = verify current email, Step 1 = change email
    var currentStep = 0

    var isVerified = false
    var resendCooldown = 0
    var logoutCountdown = 0
    var isEmailChangeInProgress = false
    var newEmail = ""
    var isChecking = false

    nonisolated(unsafe) private var verificationCheckTimer: Task<Void, Never>?
    nonisolated(unsafe) private var resendCooldownTimer: Task<Void, Never>?
    nonisolated(unsafe) private var logoutCountdownTimer: Task<Void, Never>?

    deinit {
        verificationCheckTimer?.cancel()
        resendCooldownTimer?.cancel()
        logoutCountdownTimer?.cancel()
    }

    // MARK: - Verification Check

    func startAutoCheck(authService: AuthService) {
        verificationCheckTimer?.cancel()
        verificationCheckTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }

                self?.isChecking = true
                try? await authService.currentUser?.reload()
                self?.isChecking = false

                if authService.currentUser?.isEmailVerified == true {
                    self?.isVerified = true
                    return
                }
            }
        }
    }

    func stopAutoCheck() {
        verificationCheckTimer?.cancel()
        verificationCheckTimer = nil
    }

    func checkVerificationNow(authService: AuthService) async {
        isChecking = true
        defer { isChecking = false }

        try? await authService.currentUser?.reload()
        if authService.currentUser?.isEmailVerified == true {
            isVerified = true
        }
    }

    // MARK: - Resend

    func resendVerification(authService: AuthService) async {
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

    // MARK: - Change Email

    func switchToChangeEmail() {
        currentStep = 1
        stopAutoCheck()
    }

    func switchToVerify() {
        currentStep = 0
        newEmail = ""
        isEmailChangeInProgress = false
    }

    func updateEmail(authService: AuthService) async throws {
        guard !newEmail.isEmpty else { return }

        isEmailChangeInProgress = true
        try await authService.currentUser?.sendEmailVerification(beforeUpdatingEmail: newEmail)

        // Start logout countdown
        startLogoutCountdown(authService: authService)
    }

    func startLogoutCountdown(authService: AuthService) {
        logoutCountdown = 10
        logoutCountdownTimer?.cancel()
        logoutCountdownTimer = Task { [weak self] in
            while let self, self.logoutCountdown > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.logoutCountdown -= 1
            }

            guard !Task.isCancelled else { return }
            try? authService.signOut()
        }
    }

    // MARK: - Cleanup

    func cancelTimers() {
        verificationCheckTimer?.cancel()
        resendCooldownTimer?.cancel()
        logoutCountdownTimer?.cancel()
    }
}
