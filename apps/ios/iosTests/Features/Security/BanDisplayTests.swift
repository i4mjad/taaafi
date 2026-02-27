import Testing
import Foundation
@testable import ios

// MARK: - Test Helpers

private func makeBan(
    severity: BanSeverity = .temporary,
    issuedAt: Date = Date(),
    expiresAt: Date? = nil
) -> Ban {
    Ban(
        id: "ban-test",
        userId: "user-1",
        type: .user_ban,
        scope: .app_wide,
        reason: "Test",
        description: nil,
        severity: severity,
        issuedBy: "admin",
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        isActive: true,
        restrictedFeatures: nil,
        restrictedDevices: nil,
        deviceIds: nil,
        relatedContent: nil
    )
}

@Suite("Ban.formattedDuration")
struct BanFormattedDurationTests {

    @Test("Permanent ban shows permanent label")
    func permanentBan() {
        let ban = makeBan(severity: .permanent)
        #expect(ban.formattedDuration == Strings.Ban.permanent)
    }

    @Test("Temporary with nil expiry shows unknown")
    func nilExpiry() {
        let ban = makeBan(severity: .temporary, expiresAt: nil)
        #expect(ban.formattedDuration == Strings.Ban.unknown)
    }

    @Test("Expired ban shows expired label")
    func expiredBan() {
        let ban = makeBan(
            severity: .temporary,
            issuedAt: Date.now.addingTimeInterval(-86400 * 2),
            expiresAt: Date.now.addingTimeInterval(-3600)
        )
        #expect(ban.formattedDuration == Strings.Ban.expired)
    }

    @Test("Future expiry with days shows days")
    func futureDays() {
        let issuedAt = Date.now
        let expiresAt = issuedAt.addingTimeInterval(86400 * 3) // 3 days
        let ban = makeBan(severity: .temporary, issuedAt: issuedAt, expiresAt: expiresAt)
        #expect(ban.formattedDuration.contains("3"))
    }

    @Test("Future expiry with hours shows hours")
    func futureHours() {
        let issuedAt = Date.now
        let expiresAt = issuedAt.addingTimeInterval(3600 * 5) // 5 hours
        let ban = makeBan(severity: .temporary, issuedAt: issuedAt, expiresAt: expiresAt)
        #expect(ban.formattedDuration.contains("5"))
    }

    @Test("Future expiry with minutes shows minutes")
    func futureMinutes() {
        let issuedAt = Date.now
        let expiresAt = issuedAt.addingTimeInterval(60 * 30) // 30 minutes
        let ban = makeBan(severity: .temporary, issuedAt: issuedAt, expiresAt: expiresAt)
        #expect(ban.formattedDuration.contains("30"))
    }

    @Test("Single day shows singular label")
    func singleDay() {
        let issuedAt = Date.now
        let expiresAt = issuedAt.addingTimeInterval(86400) // 1 day
        let ban = makeBan(severity: .temporary, issuedAt: issuedAt, expiresAt: expiresAt)
        #expect(ban.formattedDuration.contains(Strings.Ban.day))
    }
}

@Suite("BanType.displayText")
struct BanTypeDisplayTextTests {

    @Test("User ban shows localized text")
    func userBan() {
        #expect(BanType.user_ban.displayText == Strings.Ban.typeUser)
    }

    @Test("Device ban shows localized text")
    func deviceBan() {
        #expect(BanType.device_ban.displayText == Strings.Ban.typeDevice)
    }

    @Test("Feature ban shows localized text")
    func featureBan() {
        #expect(BanType.feature_ban.displayText == Strings.Ban.typeFeature)
    }
}

@Suite("BanScope.displayText")
struct BanScopeDisplayTextTests {

    @Test("App-wide scope shows localized text")
    func appWide() {
        #expect(BanScope.app_wide.displayText == Strings.Ban.scopeAppWide)
    }

    @Test("Feature scope shows localized text")
    func featureSpecific() {
        #expect(BanScope.feature_specific.displayText == Strings.Ban.scopeFeature)
    }
}

@Suite("Ban date formatting")
struct BanDateFormattingTests {

    @Test("formattedIssuedDate produces non-empty string")
    func issuedDate() {
        let ban = makeBan(issuedAt: Date())
        #expect(!ban.formattedIssuedDate.isEmpty)
    }

    @Test("formattedExpiresDate is nil when no expiry")
    func noExpiry() {
        let ban = makeBan(expiresAt: nil)
        #expect(ban.formattedExpiresDate == nil)
    }

    @Test("formattedExpiresDate produces non-empty string when set")
    func withExpiry() {
        let ban = makeBan(expiresAt: Date.now.addingTimeInterval(86400))
        #expect(ban.formattedExpiresDate != nil)
        #expect(!ban.formattedExpiresDate!.isEmpty)
    }
}
