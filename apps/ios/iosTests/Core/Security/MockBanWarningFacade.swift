import Foundation
@testable import ios

final class MockBanWarningFacade: BanWarningFacadeProtocol {
    var currentUserId: String? = "test-user-123"
    var deviceId = "test-device-123"
    var deviceBans: [Ban] = []
    var userBans: [Ban] = []
    var userWarnings: [Warning] = []
    var isUserBanned = false
    var initializeDeviceTrackingCallCount = 0

    func getCurrentDeviceId() -> String {
        deviceId
    }

    func getDeviceBans(deviceId: String) async -> [Ban] {
        deviceBans
    }

    func getCurrentUserBans() async -> [Ban] {
        userBans
    }

    func getCurrentUserWarnings() async -> [Warning] {
        userWarnings
    }

    func isCurrentUserBannedFromApp() async -> Bool {
        isUserBanned
    }

    func initializeDeviceTracking() async {
        initializeDeviceTrackingCallCount += 1
    }
}
