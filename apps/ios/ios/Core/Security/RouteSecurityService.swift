import Foundation
import FirebaseAuth

/// Manages routing based on security state with intelligent caching
/// Ported from: apps/mobile/lib/core/routing/route_security_service.dart
@Observable
@MainActor
final class RouteSecurityService {

    private let facade: BanWarningFacade

    // Cache for device ban status
    private var cachedDeviceBanResult: SecurityCheckResult?
    private var deviceBanCacheTime: Date?

    // Cache for user ban status
    private var cachedUserBanResult: SecurityCheckResult?
    private var userBanCacheTime: Date?
    private var cachedUserId: String?

    // Cache durations
    private static let deviceBanCacheDuration: TimeInterval = 10 * 60 // 10 minutes
    private static let userBanCacheDuration: TimeInterval = 3 * 60   // 3 minutes

    init(facade: BanWarningFacade) {
        self.facade = facade
    }

    /// Full security check: device ban > auth > user ban
    func checkSecurity() async -> SecurityCheckResult {
        // Step 1: Check device bans (highest priority)
        let deviceResult = await checkDeviceBans()
        if deviceResult.isBlocked { return deviceResult }

        // Step 2: Check authentication
        guard let user = Auth.auth().currentUser else {
            return .unauthenticated
        }

        // Step 3: Check user bans
        let userResult = await checkUserBans(userId: user.uid)
        if userResult.isBlocked { return userResult }

        return .allowed
    }

    // MARK: - Device Ban Check (cached)

    private func checkDeviceBans() async -> SecurityCheckResult {
        // Check cache
        if let cached = cachedDeviceBanResult,
           let cacheTime = deviceBanCacheTime,
           Date().timeIntervalSince(cacheTime) < Self.deviceBanCacheDuration {
            return cached
        }

        let deviceId = facade.getCurrentDeviceId()
        let deviceBans = await facade.getDeviceBans(deviceId: deviceId)

        let result: SecurityCheckResult
        if !deviceBans.isEmpty {
            result = .deviceBanned(
                message: "Device is banned from accessing the application",
                deviceId: deviceId
            )
        } else {
            result = .allowed
        }

        cachedDeviceBanResult = result
        deviceBanCacheTime = Date()
        return result
    }

    // MARK: - User Ban Check (cached)

    private func checkUserBans(userId: String) async -> SecurityCheckResult {
        // Check cache (must match current user)
        if let cached = cachedUserBanResult,
           let cacheTime = userBanCacheTime,
           cachedUserId == userId,
           Date().timeIntervalSince(cacheTime) < Self.userBanCacheDuration {
            return cached
        }

        let isBanned = await facade.isCurrentUserBannedFromApp()

        let result: SecurityCheckResult
        if isBanned {
            result = .userBanned(
                message: "User account is banned from the application",
                userId: userId
            )
        } else {
            result = .allowed
        }

        cachedUserBanResult = result
        userBanCacheTime = Date()
        cachedUserId = userId
        return result
    }

    // MARK: - Cache Management

    func clearDeviceBanCache() {
        cachedDeviceBanResult = nil
        deviceBanCacheTime = nil
    }

    func clearUserBanCache() {
        cachedUserBanResult = nil
        userBanCacheTime = nil
        cachedUserId = nil
    }

    func clearAllCaches() {
        clearDeviceBanCache()
        clearUserBanCache()
    }

    func onUserLogout() {
        clearUserBanCache()
    }
}

// MARK: - Security Check Result

enum SecurityCheckResult {
    case allowed
    case deviceBanned(message: String, deviceId: String)
    case userBanned(message: String, userId: String)
    case unauthenticated
    case error(String)

    var isBlocked: Bool {
        switch self {
        case .deviceBanned, .userBanned: return true
        default: return false
        }
    }

    var isDeviceBanned: Bool {
        if case .deviceBanned = self { return true }
        return false
    }

    var isUserBanned: Bool {
        if case .userBanned = self { return true }
        return false
    }

    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .deviceBanned(let msg, _), .userBanned(let msg, _): return msg
        case .error(let msg): return msg
        default: return nil
        }
    }
}
