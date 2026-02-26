import Testing
import Foundation
@testable import ios

// MARK: - Test Helpers

private func makeBan(
    isActive: Bool = true,
    expiresAt: Date? = nil,
    type: BanType = .user_ban,
    scope: BanScope = .app_wide,
    severity: BanSeverity = .permanent
) -> Ban {
    Ban(
        id: "ban-1",
        userId: "user-1",
        type: type,
        scope: scope,
        reason: "Test ban",
        description: nil,
        severity: severity,
        issuedBy: "admin",
        issuedAt: Date(),
        expiresAt: expiresAt,
        isActive: isActive,
        restrictedFeatures: nil,
        restrictedDevices: nil,
        deviceIds: nil,
        relatedContent: nil
    )
}

@Suite("Ban.isExpired")
struct BanIsExpiredTests {

    @Test("Expired date returns true")
    func expiredDate() {
        let ban = makeBan(expiresAt: Date.distantPast)
        #expect(ban.isExpired)
    }

    @Test("Future date returns false")
    func futureDate() {
        let ban = makeBan(expiresAt: Date.distantFuture)
        #expect(!ban.isExpired)
    }

    @Test("Nil expiresAt returns false (permanent ban)")
    func nilExpiry() {
        let ban = makeBan(expiresAt: nil)
        #expect(!ban.isExpired)
    }
}

@Suite("Ban.isCurrentlyActive")
struct BanIsCurrentlyActiveTests {

    @Test("Active and not expired returns true")
    func activeNotExpired() {
        let ban = makeBan(isActive: true, expiresAt: Date.distantFuture)
        #expect(ban.isCurrentlyActive)
    }

    @Test("Active with nil expiry (permanent) returns true")
    func activePermanent() {
        let ban = makeBan(isActive: true, expiresAt: nil)
        #expect(ban.isCurrentlyActive)
    }

    @Test("Active but expired returns false")
    func activeButExpired() {
        let ban = makeBan(isActive: true, expiresAt: Date.distantPast)
        #expect(!ban.isCurrentlyActive)
    }

    @Test("Inactive returns false regardless of expiry")
    func inactive() {
        let ban = makeBan(isActive: false, expiresAt: Date.distantFuture)
        #expect(!ban.isCurrentlyActive)
    }
}

@Suite("Ban enums raw value round-trips")
struct BanEnumTests {

    @Test("BanType round-trips")
    func banType() {
        for value in [BanType.user_ban, .device_ban, .feature_ban] {
            #expect(BanType(rawValue: value.rawValue) == value)
        }
    }

    @Test("BanScope round-trips")
    func banScope() {
        for value in [BanScope.app_wide, .feature_specific] {
            #expect(BanScope(rawValue: value.rawValue) == value)
        }
    }

    @Test("BanSeverity round-trips")
    func banSeverity() {
        for value in [BanSeverity.temporary, .permanent] {
            #expect(BanSeverity(rawValue: value.rawValue) == value)
        }
    }
}
