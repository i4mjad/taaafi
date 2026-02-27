import Foundation
import FirebaseAuth

/// Facade coordinating ban, warning, and feature services
/// Provides simplified interface for UI components
/// Ported from: apps/mobile/lib/features/account/application/ban_warning_facade.dart
final class BanWarningFacade: BanWarningFacadeProtocol {

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    private let banService: BanService
    private let warningService: WarningService
    private let featureService: AppFeatureService
    private let deviceTrackingService: DeviceTrackingService

    init(
        banService: BanService = BanService(),
        warningService: WarningService = WarningService(),
        featureService: AppFeatureService = AppFeatureService(),
        deviceTrackingService: DeviceTrackingService
    ) {
        self.banService = banService
        self.warningService = warningService
        self.featureService = featureService
        self.deviceTrackingService = deviceTrackingService
    }

    // MARK: - Feature Access

    func canUserAccessFeature(_ featureUniqueName: String) async -> Bool {
        do {
            return try await banService.canUserPerformAction(
                featureUniqueName: featureUniqueName,
                deviceId: deviceTrackingService.deviceId
            )
        } catch {
            return false // Fail safe
        }
    }

    // MARK: - User Status

    func getCurrentUserBans() async -> [Ban] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        return (try? await banService.getUserBans(userId: uid)) ?? []
    }

    func getCurrentUserWarnings() async -> [Warning] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        return (try? await warningService.getUserWarnings(userId: uid)) ?? []
    }

    func getCurrentUserHighPriorityWarnings() async -> [Warning] {
        return (try? await warningService.getCurrentUserHighPriorityWarnings()) ?? []
    }

    func isCurrentUserBannedFromApp() async -> Bool {
        return (try? await banService.isCurrentUserBannedFromApp()) ?? false
    }

    // MARK: - Device Bans

    func getDeviceBans(deviceId: String) async -> [Ban] {
        return (try? await banService.getDeviceBans(deviceId: deviceId)) ?? []
    }

    func getCurrentDeviceId() -> String {
        deviceTrackingService.deviceId
    }

    // MARK: - Feature Details

    func getAppFeatures() async -> [AppFeature] {
        return (try? await featureService.getAppFeatures()) ?? []
    }

    func getFeatureByUniqueName(_ uniqueName: String) async -> AppFeature? {
        return try? await featureService.getFeatureByUniqueName(uniqueName)
    }

    // MARK: - Device Tracking

    func initializeDeviceTracking() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await deviceTrackingService.updateUserDeviceIds(userId: uid)
    }
}
