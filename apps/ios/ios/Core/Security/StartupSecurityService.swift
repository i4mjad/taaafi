import Foundation

/// Runs during app startup to check device/user bans and initialize device tracking
/// Ported from: apps/mobile/lib/features/account/application/startup_security_service.dart
final class StartupSecurityService {

    private let facade: BanWarningFacadeProtocol

    init(facade: BanWarningFacadeProtocol) {
        self.facade = facade
    }

    /// Initialize security during app startup
    /// Returns the startup result indicating whether the user/device is banned
    func initializeAppSecurity() async -> SecurityStartupResult {
        guard facade.currentUserId != nil else {
            let deviceId = facade.getCurrentDeviceId()
            return .success(deviceId: deviceId)
        }

        return await performSecurityCheck()
    }

    private func performSecurityCheck() async -> SecurityStartupResult {
        do {
            // Device tracking is handled by DeviceTrackingService.startListeningToAuthState(),
            // so we skip initializeDeviceTracking() here to avoid redundant Firestore calls.
            let deviceId = facade.getCurrentDeviceId()

            let deviceBans = await facade.getDeviceBans(deviceId: deviceId)
            if !deviceBans.isEmpty {
                return .deviceBanned(
                    message: "This device has been permanently restricted from accessing the application. Contact support if you believe this is an error.",
                    deviceId: deviceId
                )
            }

            if let userId = facade.currentUserId {
                let isBanned = await facade.isCurrentUserBannedFromApp()
                if isBanned {
                    return .userBanned(
                        message: "Your account has been restricted from accessing the application.",
                        userId: userId
                    )
                }
            }

            return .success(deviceId: deviceId)
        } catch {
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
