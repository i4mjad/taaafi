import Foundation
@testable import ios

final class MockBanWarningFacade: BanWarningFacadeProtocol {
    var deviceId = "test-device-123"
    var deviceBans: [Ban] = []
    var isUserBanned = false
    var initializeDeviceTrackingCallCount = 0

    func getCurrentDeviceId() -> String {
        deviceId
    }

    func getDeviceBans(deviceId: String) async -> [Ban] {
        deviceBans
    }

    func isCurrentUserBannedFromApp() async -> Bool {
        isUserBanned
    }

    func initializeDeviceTracking() async {
        initializeDeviceTrackingCallCount += 1
    }
}
