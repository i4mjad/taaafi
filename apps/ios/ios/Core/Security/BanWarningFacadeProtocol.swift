import Foundation

/// Protocol enabling mock injection for security service tests
protocol BanWarningFacadeProtocol {
    var currentUserId: String? { get }
    func getCurrentDeviceId() -> String
    func getDeviceBans(deviceId: String) async -> [Ban]
    func isCurrentUserBannedFromApp() async -> Bool
    func initializeDeviceTracking() async
}
