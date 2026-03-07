import Testing
@testable import ios

@Suite("AccountViewModel")
struct AccountViewModelTests {

    // Note: Full sign-out testing requires AuthService protocol extraction.
    // For now, we test the observable state management.

    @Test("Initial state has no errors")
    @MainActor
    func initialState() {
        let vm = AccountViewModel(authService: AuthService())
        #expect(vm.signOutError == nil)
        #expect(vm.showSignOutConfirmation == false)
        #expect(vm.showResetDataSheet == false)
        #expect(vm.showContactUsSheet == false)
    }
}
