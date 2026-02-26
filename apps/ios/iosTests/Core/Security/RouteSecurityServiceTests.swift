import Testing
import Foundation
@testable import ios

@Suite("RouteSecurityService")
@MainActor
struct RouteSecurityServiceTests {

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

    // MARK: - checkDeviceBans (via internal cache testing)

    @Test("No device bans returns allowed from device check")
    func noDeviceBansAllowed() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = []
        let service = RouteSecurityService(facade: mock)

        // checkSecurity checks device bans first; with no bans and no Auth user
        // it will proceed to auth check and return .unauthenticated
        let result = await service.checkSecurity()
        #expect(!result.isDeviceBanned)
    }

    @Test("Device bans present returns deviceBanned")
    func deviceBansReturnDeviceBanned() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = [Self.makeBan()]
        let service = RouteSecurityService(facade: mock)

        let result = await service.checkSecurity()
        #expect(result.isDeviceBanned)
        #expect(result.isBlocked)
    }

    // MARK: - Cache behavior

    @Test("Second call within cache window returns cached result")
    func cacheHit() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = [Self.makeBan()]
        let service = RouteSecurityService(facade: mock)

        let first = await service.checkSecurity()
        #expect(first.isDeviceBanned)

        // Clear device bans — but cache should still return deviceBanned
        mock.deviceBans = []
        let second = await service.checkSecurity()
        #expect(second.isDeviceBanned)
    }

    @Test("clearDeviceBanCache forces re-check")
    func clearDeviceBanCache() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = [Self.makeBan()]
        let service = RouteSecurityService(facade: mock)

        let first = await service.checkSecurity()
        #expect(first.isDeviceBanned)

        // Clear bans and cache
        mock.deviceBans = []
        service.clearDeviceBanCache()

        // Now should re-fetch and find no bans
        let second = await service.checkSecurity()
        #expect(!second.isDeviceBanned)
    }

    @Test("clearAllCaches resets both device and user caches")
    func clearAllCaches() async {
        let mock = MockBanWarningFacade()
        mock.deviceBans = [Self.makeBan()]
        let service = RouteSecurityService(facade: mock)

        _ = await service.checkSecurity()

        mock.deviceBans = []
        service.clearAllCaches()

        let result = await service.checkSecurity()
        #expect(!result.isDeviceBanned)
    }

    // MARK: - Unauthenticated

    @Test("No bans and no auth user returns unauthenticated")
    func unauthenticatedWhenNoUser() async {
        let mock = MockBanWarningFacade()
        let service = RouteSecurityService(facade: mock)

        let result = await service.checkSecurity()
        // Without a real Firebase Auth user, this returns .unauthenticated
        #expect(!result.isBlocked)
    }
}
