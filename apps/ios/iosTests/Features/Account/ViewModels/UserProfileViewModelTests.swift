import Testing
import Foundation
@testable import ios

private func makeWarning(id: String = "w-1") -> Warning {
    Warning(
        id: id,
        userId: "user-1",
        type: .content_violation,
        reason: "Test warning",
        description: nil,
        severity: .medium,
        issuedBy: "admin",
        issuedAt: Date(),
        isActive: true,
        deviceIds: nil,
        relatedContent: nil,
        reportId: nil
    )
}

private func makeBan(id: String = "b-1") -> Ban {
    Ban(
        id: id,
        userId: "user-1",
        type: .user_ban,
        scope: .app_wide,
        reason: "Test ban",
        description: nil,
        severity: .temporary,
        issuedBy: "admin",
        issuedAt: Date(),
        expiresAt: Date.distantFuture,
        isActive: true,
        restrictedFeatures: nil,
        restrictedDevices: nil,
        deviceIds: nil,
        relatedContent: nil
    )
}

@Suite("UserProfileViewModel")
struct UserProfileViewModelTests {

    @Test("loadWarnings populates warnings from facade")
    @MainActor
    func loadWarnings() async {
        let mock = MockBanWarningFacade()
        mock.userWarnings = [makeWarning()]
        let vm = UserProfileViewModel(banWarningFacade: mock)

        await vm.loadWarnings()

        #expect(vm.warnings.count == 1)
        #expect(vm.isLoadingWarnings == false)
    }

    @Test("loadBans populates bans from facade")
    @MainActor
    func loadBans() async {
        let mock = MockBanWarningFacade()
        mock.userBans = [makeBan()]
        let vm = UserProfileViewModel(banWarningFacade: mock)

        await vm.loadBans()

        #expect(vm.bans.count == 1)
        #expect(vm.isLoadingBans == false)
    }

    @Test("Empty warnings returns empty array")
    @MainActor
    func emptyWarnings() async {
        let mock = MockBanWarningFacade()
        let vm = UserProfileViewModel(banWarningFacade: mock)

        await vm.loadWarnings()

        #expect(vm.warnings.isEmpty)
    }

    @Test("refreshWarnings clears and reloads")
    @MainActor
    func refreshWarnings() async {
        let mock = MockBanWarningFacade()
        mock.userWarnings = [makeWarning()]
        let vm = UserProfileViewModel(banWarningFacade: mock)

        await vm.loadWarnings()
        #expect(vm.warnings.count == 1)

        mock.userWarnings = [makeWarning(id: "w-2"), makeWarning(id: "w-3")]
        await vm.refreshWarnings()
        #expect(vm.warnings.count == 2)
    }
}
