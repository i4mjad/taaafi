import Testing
import Foundation
@testable import ios

@Suite("ConfirmEmailViewModel")
@MainActor
struct ConfirmEmailViewModelTests {

    // MARK: - Initial State

    @Test("Initial state has step 0 and is not verified")
    func initialState() {
        let vm = ConfirmEmailViewModel()
        #expect(vm.currentStep == 0)
        #expect(!vm.isVerified)
        #expect(vm.resendCooldown == 0)
        #expect(vm.logoutCountdown == 0)
        #expect(!vm.isEmailChangeInProgress)
        #expect(vm.newEmail == "")
        #expect(!vm.isChecking)
    }

    // MARK: - Step Transitions

    @Test("switchToChangeEmail moves to step 1")
    func switchToChangeEmail() {
        let vm = ConfirmEmailViewModel()
        vm.switchToChangeEmail()
        #expect(vm.currentStep == 1)
    }

    @Test("switchToVerify moves back to step 0 and resets state")
    func switchToVerify() {
        let vm = ConfirmEmailViewModel()
        vm.currentStep = 1
        vm.newEmail = "new@example.com"
        vm.isEmailChangeInProgress = true

        vm.switchToVerify()

        #expect(vm.currentStep == 0)
        #expect(vm.newEmail == "")
        #expect(!vm.isEmailChangeInProgress)
    }

    // MARK: - Cooldown Logic

    @Test("startResendCooldown sets cooldown to 60")
    func resendCooldownStarts() {
        let vm = ConfirmEmailViewModel()
        vm.startResendCooldown()
        #expect(vm.resendCooldown == 60)
        vm.cancelTimers()
    }

    // MARK: - Cancel Timers

    @Test("cancelTimers cleans up without crashing")
    func cancelTimers() {
        let vm = ConfirmEmailViewModel()
        vm.startResendCooldown()
        vm.cancelTimers()
        // Should not crash
    }
}
