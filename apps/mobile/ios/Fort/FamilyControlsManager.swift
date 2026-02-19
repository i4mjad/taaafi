import Foundation
import FamilyControls
import ManagedSettings

/// Manages FamilyControls authorization and activity selection.
/// Used by Phase 1 for auth check / Phase 3 for blocking.
@available(iOS 16.0, *)
class FamilyControlsManager: ObservableObject {

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    /// Request FamilyControls authorization for individual (non-child) use.
    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        await MainActor.run {
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        }
    }

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
}
