import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Handles all ban queries: user bans, device bans, feature bans
/// Ported from: apps/mobile/lib/features/account/application/ban_service.dart
final class BanService {

    private let db = Firestore.firestore()

    /// Get user's active bans
    func getUserBans(userId: String) async throws -> [Ban] {
        let snapshot = try await db.collection("bans")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "issuedAt", descending: true)
            .getDocuments()

        return snapshot.documents
            .compactMap { Ban.fromFirestore($0) }
            .filter { $0.isCurrentlyActive }
    }

    /// Check if user is banned from a specific feature
    func isUserBannedFromFeature(userId: String, featureUniqueName: String) async throws -> Bool {
        let bans = try await getUserBans(userId: userId)

        for ban in bans {
            if ban.scope == .app_wide { return true }
            if ban.scope == .feature_specific,
               let features = ban.restrictedFeatures,
               features.contains(featureUniqueName) {
                return true
            }
        }

        return false
    }

    /// Check if device is banned
    func isDeviceBanned(deviceId: String) async throws -> Bool {
        let bans = try await getDeviceBans(deviceId: deviceId)
        return !bans.isEmpty
    }

    /// Get all active bans for a specific device
    func getDeviceBans(deviceId: String) async throws -> [Ban] {
        // Primary: query device bans with restrictedDevices containing this device
        do {
            let snapshot = try await db.collection("bans")
                .whereField("type", isEqualTo: BanType.device_ban.rawValue)
                .whereField("isActive", isEqualTo: true)
                .whereField("restrictedDevices", arrayContains: deviceId)
                .getDocuments()

            let bans = snapshot.documents
                .compactMap { Ban.fromFirestore($0) }
                .filter { $0.isCurrentlyActive }

            return bans
        } catch {
            // Fallback: query all active device bans and filter manually
            let snapshot = try await db.collection("bans")
                .whereField("type", isEqualTo: BanType.device_ban.rawValue)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            return snapshot.documents
                .compactMap { Ban.fromFirestore($0) }
                .filter { ban in
                    ban.isCurrentlyActive &&
                    ban.restrictedDevices?.contains(deviceId) == true
                }
        }
    }

    /// Check if current user has any app-wide ban
    func isCurrentUserBannedFromApp() async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let bans = try await getUserBans(userId: uid)
        return bans.contains { $0.scope == .app_wide }
    }

    /// Check if current user can perform action on a feature
    func canUserPerformAction(featureUniqueName: String, deviceId: String) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }

        if try await isDeviceBanned(deviceId: deviceId) { return false }
        if try await isUserBannedFromFeature(userId: uid, featureUniqueName: featureUniqueName) { return false }

        return true
    }

    /// Get ban details for a specific feature
    func getUserFeatureBan(userId: String, featureUniqueName: String) async throws -> Ban? {
        let bans = try await getUserBans(userId: userId)

        // Check app-wide bans first
        if let appWideBan = bans.first(where: { $0.scope == .app_wide }) {
            return appWideBan
        }

        // Then feature-specific
        return bans.first { ban in
            ban.scope == .feature_specific &&
            ban.restrictedFeatures?.contains(featureUniqueName) == true
        }
    }

    /// Get scope for ban type (auto-determined)
    func scopeForBanType(_ type: BanType) -> BanScope {
        switch type {
        case .user_ban, .device_ban: return .app_wide
        case .feature_ban: return .feature_specific
        }
    }
}
