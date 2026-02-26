import Foundation

/// Protocol enabling mock injection for security service tests
protocol BanWarningFacadeProtocol {
    func getCurrentDeviceId() -> String
    func getDeviceBans(deviceId: String) async -> [Ban]
    func isCurrentUserBannedFromApp() async -> Bool
    func initializeDeviceTracking() async
}
