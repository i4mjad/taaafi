import Testing
import Foundation
@testable import ios

@Suite("StartupSecurityService")
@MainActor
struct StartupSecurityServiceTests {

    // MARK: - Helpers

    private static func makeBan() -> Ban {
        Ban(
            id: "ban-1",
            userId: "user-1",
            type: .device_ban,
            scope: .app_wide,
            reason: "Test",
            description: nil,
            severity: .permanent,
            issuedBy: "admin",
            issuedAt: Date(),
            expiresAt: nil,
            isActive: true,
            restrictedFeatures: nil,
            restrictedDevices: nil,
            deviceIds: nil,
            relatedContent: nil
        )
    }

    // MARK: - No bans

    @Test("No bans returns success with deviceId")
    func noBansReturnsSuccess() async {
        let mock = MockBanWarningFacade()
        mock.deviceId = "device-abc"
        let service = StartupSecurityService(facade: mock)

        let result = await service.initializeAppSecurity()
        #expect(result.isSuccess)
        #expect(!result.isBlocked)
        if case .success(let deviceId) = result {
            #expect(deviceId == "device-abc")
        } else {
            Issue.record("Expected .success, got \(result)")
        }
    }

    // MARK: - Device banned

    @Test("Device bans returns deviceBanned")
    func deviceBansReturnsDeviceBanned() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = [Self.makeBan()]
        let service = StartupSecurityService(facade: mock)

        let result = await service.initializeAppSecurity()
        #expect(result.isBlocked)
        if case .deviceBanned(_, let deviceId) = result {
            #expect(deviceId == "test-device-123")
        } else {
            Issue.record("Expected .deviceBanned, got \(result)")
        }
    }

    // MARK: - initializeDeviceTracking called

    @Test("initializeDeviceTracking is called during startup")
    func deviceTrackingInitialized() async {
        let mock = MockBanWarningFacade()
        let service = StartupSecurityService(facade: mock)

        _ = await service.initializeAppSecurity()
        #expect(mock.initializeDeviceTrackingCallCount == 1)
    }

    // MARK: - Success message

    @Test("Success result has nil message")
    func successNilMessage() async {
        let mock = MockBanWarningFacade()
        let service = StartupSecurityService(facade: mock)

        let result = await service.initializeAppSecurity()
        #expect(result.message == nil)
    }

    @Test("DeviceBanned result has non-nil message")
    func deviceBannedHasMessage() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = [Self.makeBan()]
        let service = StartupSecurityService(facade: mock)

        let result = await service.initializeAppSecurity()
        #expect(result.message != nil)
    }
}
