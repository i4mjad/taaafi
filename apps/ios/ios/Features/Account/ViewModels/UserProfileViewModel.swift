import Foundation

@Observable
@MainActor
final class UserProfileViewModel {
    private let banWarningFacade: BanWarningFacadeProtocol

    private(set) var warnings: [Warning] = []
    private(set) var bans: [Ban] = []
    private(set) var isLoadingWarnings = false
    private(set) var isLoadingBans = false

    init(banWarningFacade: BanWarningFacadeProtocol) {
        self.banWarningFacade = banWarningFacade
    }

    func loadWarnings() async {
        isLoadingWarnings = true
        warnings = await banWarningFacade.getCurrentUserWarnings()
        isLoadingWarnings = false
    }

    func loadBans() async {
        isLoadingBans = true
        bans = await banWarningFacade.getCurrentUserBans()
        isLoadingBans = false
    }

    func refreshWarnings() async {
        warnings = []
        await loadWarnings()
    }

    func refreshBans() async {
        bans = []
        await loadBans()
    }
}
