import Foundation
import FirebaseAuth

/// Runs during app startup to check device/user bans and initialize device tracking
/// Ported from: apps/mobile/lib/features/account/application/startup_security_service.dart
@Observable
@MainActor
final class StartupSecurityService {

    private let facade: BanWarningFacadeProtocol

    init(facade: BanWarningFacadeProtocol) {
        self.facade = facade
    }

    private static let timeoutSeconds: UInt64 = 10

    /// Initialize security during app startup
    /// Returns the startup result indicating whether the user/device is banned
    func initializeAppSecurity() async -> SecurityStartupResult {
        // Skip Firestore security checks when user is not authenticated.
        // Auth is handled in a later phase — unauthenticated users proceed directly.
        guard Auth.auth().currentUser != nil else {
            let deviceId = facade.getCurrentDeviceId()
            return .success(deviceId: deviceId)
        }

        // Race the security check against a timeout to prevent app hanging
        // on network/permission errors
        return await withTaskGroup(of: SecurityStartupResult.self) { group in
            group.addTask { await self.performSecurityCheck() }
            group.addTask {
                try? await Task.sleep(nanoseconds: Self.timeoutSeconds * 1_000_000_000)
                return .warning(
                    message: "Security check timed out",
                    error: "Firestore query did not complete within \(Self.timeoutSeconds)s"
                )
            }

            // Return whichever finishes first
            let result = await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func performSecurityCheck() async -> SecurityStartupResult {
        do {
            // Step 1: Initialize device tracking
            await facade.initializeDeviceTracking()
            let deviceId = facade.getCurrentDeviceId()

            // Step 2: Check device-wide bans (highest priority)
            let deviceBans = await facade.getDeviceBans(deviceId: deviceId)
            if !deviceBans.isEmpty {
                return .deviceBanned(
                    message: "This device has been permanently restricted from accessing the application. Contact support if you believe this is an error.",
                    deviceId: deviceId
                )
            }

            // Step 3: Check user-level bans
            if let user = Auth.auth().currentUser {
                let isBanned = await facade.isCurrentUserBannedFromApp()
                if isBanned {
                    return .userBanned(
                        message: "Your account has been restricted from accessing the application.",
                        userId: user.uid
                    )
                }
            }

            // Feature access is checked lazily, not at startup
            return .success(deviceId: deviceId)
        } catch {
            // Fail safely — allow app to continue but log the error
            return .warning(
                message: "Security check failed, proceeding with limited functionality",
                error: error.localizedDescription
            )
        }
    }
}

// MARK: - Startup Result

enum SecurityStartupResult {
    case success(deviceId: String)
    case deviceBanned(message: String, deviceId: String)
    case userBanned(message: String, userId: String)
    case warning(message: String, error: String)

    var isBlocked: Bool {
        switch self {
        case .deviceBanned, .userBanned: return true
        default: return false
        }
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .deviceBanned(let msg, _), .userBanned(let msg, _), .warning(let msg, _): return msg
        case .success: return nil
        }
    }
}
