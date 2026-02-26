import Testing
@testable import ios

@Suite("SecurityCheckResult")
struct SecurityCheckResultTests {

    // MARK: - isBlocked

    @Test("deviceBanned is blocked")
    func deviceBannedBlocked() {
        let result = SecurityCheckResult.deviceBanned(message: "banned", deviceId: "d1")
        #expect(result.isBlocked)
    }

    @Test("userBanned is blocked")
    func userBannedBlocked() {
        let result = SecurityCheckResult.userBanned(message: "banned", userId: "u1")
        #expect(result.isBlocked)
    }

    @Test("allowed is not blocked")
    func allowedNotBlocked() {
        #expect(!SecurityCheckResult.allowed.isBlocked)
    }

    @Test("unauthenticated is not blocked")
    func unauthenticatedNotBlocked() {
        #expect(!SecurityCheckResult.unauthenticated.isBlocked)
    }

    @Test("error is not blocked")
    func errorNotBlocked() {
        #expect(!SecurityCheckResult.error("something").isBlocked)
    }

    // MARK: - Specific predicates

    @Test("isDeviceBanned only true for deviceBanned")
    func isDeviceBanned() {
        #expect(SecurityCheckResult.deviceBanned(message: "", deviceId: "").isDeviceBanned)
        #expect(!SecurityCheckResult.userBanned(message: "", userId: "").isDeviceBanned)
        #expect(!SecurityCheckResult.allowed.isDeviceBanned)
    }

    @Test("isUserBanned only true for userBanned")
    func isUserBanned() {
        #expect(SecurityCheckResult.userBanned(message: "", userId: "").isUserBanned)
        #expect(!SecurityCheckResult.deviceBanned(message: "", deviceId: "").isUserBanned)
        #expect(!SecurityCheckResult.allowed.isUserBanned)
    }

    @Test("isAllowed only true for allowed")
    func isAllowed() {
        #expect(SecurityCheckResult.allowed.isAllowed)
        #expect(!SecurityCheckResult.unauthenticated.isAllowed)
        #expect(!SecurityCheckResult.deviceBanned(message: "", deviceId: "").isAllowed)
    }

    // MARK: - message

    @Test("deviceBanned carries message")
    func deviceBannedMessage() {
        let result = SecurityCheckResult.deviceBanned(message: "device msg", deviceId: "d1")
        #expect(result.message == "device msg")
    }

    @Test("userBanned carries message")
    func userBannedMessage() {
        let result = SecurityCheckResult.userBanned(message: "user msg", userId: "u1")
        #expect(result.message == "user msg")
    }

    @Test("error carries message")
    func errorMessage() {
        #expect(SecurityCheckResult.error("err").message == "err")
    }

    @Test("allowed has nil message")
    func allowedNilMessage() {
        #expect(SecurityCheckResult.allowed.message == nil)
    }

    @Test("unauthenticated has nil message")
    func unauthenticatedNilMessage() {
        #expect(SecurityCheckResult.unauthenticated.message == nil)
    }
}

@Suite("SecurityStartupResult")
struct SecurityStartupResultTests {

    // MARK: - isBlocked

    @Test("deviceBanned is blocked")
    func deviceBannedBlocked() {
        let result = SecurityStartupResult.deviceBanned(message: "banned", deviceId: "d1")
        #expect(result.isBlocked)
    }

    @Test("userBanned is blocked")
    func userBannedBlocked() {
        let result = SecurityStartupResult.userBanned(message: "banned", userId: "u1")
        #expect(result.isBlocked)
    }

    @Test("success is not blocked")
    func successNotBlocked() {
        #expect(!SecurityStartupResult.success(deviceId: "d1").isBlocked)
    }

    @Test("warning is not blocked")
    func warningNotBlocked() {
        #expect(!SecurityStartupResult.warning(message: "warn", error: "err").isBlocked)
    }

    // MARK: - isSuccess

    @Test("success returns true for isSuccess")
    func isSuccess() {
        #expect(SecurityStartupResult.success(deviceId: "d1").isSuccess)
    }

    @Test("non-success returns false for isSuccess")
    func notSuccess() {
        #expect(!SecurityStartupResult.deviceBanned(message: "", deviceId: "").isSuccess)
        #expect(!SecurityStartupResult.warning(message: "", error: "").isSuccess)
    }

    // MARK: - message

    @Test("deviceBanned carries message")
    func deviceBannedMessage() {
        let result = SecurityStartupResult.deviceBanned(message: "device msg", deviceId: "d1")
        #expect(result.message == "device msg")
    }

    @Test("userBanned carries message")
    func userBannedMessage() {
        let result = SecurityStartupResult.userBanned(message: "user msg", userId: "u1")
        #expect(result.message == "user msg")
    }

    @Test("warning carries message")
    func warningMessage() {
        let result = SecurityStartupResult.warning(message: "warn msg", error: "err")
        #expect(result.message == "warn msg")
    }

    @Test("success has nil message")
    func successNilMessage() {
        #expect(SecurityStartupResult.success(deviceId: "d1").message == nil)
    }
}
