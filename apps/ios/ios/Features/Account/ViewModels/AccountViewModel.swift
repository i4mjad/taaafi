import SwiftUI
import StoreKit

@Observable
@MainActor
final class AccountViewModel {
    private let authService: AuthService

    var showSignOutConfirmation = false
    var showResetDataSheet = false
    var showContactUsSheet = false
    var signOutError: Error?

    @ObservationIgnored
    @AppStorage("appTheme") var appTheme: String = "system"

    init(authService: AuthService) {
        self.authService = authService
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            signOutError = error
        }
    }

    func requestAppReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        AppStore.requestReview(in: scene)
    }
}
