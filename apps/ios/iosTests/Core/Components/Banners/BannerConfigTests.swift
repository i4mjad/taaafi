import Testing
@testable import ios

@Suite("BannerConfig mapping")
struct BannerConfigTests {

    @Test("Loading returns nil")
    func loadingNil() {
        #expect(bannerConfig(for: .loading) == nil)
    }

    @Test("Ok returns nil")
    func okNil() {
        #expect(bannerConfig(for: .ok) == nil)
    }

    @Test("needCompleteRegistration returns warning config")
    func completeRegistration() {
        let config = bannerConfig(for: .needCompleteRegistration)
        #expect(config != nil)
        #expect(config?.icon == "exclamationmark.triangle")
    }

    @Test("needConfirmDetails returns error-styled config")
    func confirmDetails() {
        let config = bannerConfig(for: .needConfirmDetails)
        #expect(config != nil)
        #expect(config?.icon == "exclamationmark.circle")
    }

    @Test("needEmailVerification returns primary-styled config")
    func emailVerification() {
        let config = bannerConfig(for: .needEmailVerification)
        #expect(config != nil)
        #expect(config?.icon == "envelope")
    }

    @Test("pendingDeletion returns error-styled config")
    func pendingDeletion() {
        let config = bannerConfig(for: .pendingDeletion)
        #expect(config != nil)
        #expect(config?.icon == "person.crop.circle.badge.xmark")
    }

    @Test("error returns error-styled config")
    func errorConfig() {
        let config = bannerConfig(for: .error)
        #expect(config != nil)
        #expect(config?.icon == "exclamationmark.circle")
    }

    @Test("All non-nil configs have required fields populated")
    func allConfigsPopulated() {
        let statusesWithConfigs: [AccountStatus] = [
            .needCompleteRegistration, .needConfirmDetails,
            .needEmailVerification, .pendingDeletion, .error
        ]
        for status in statusesWithConfigs {
            let config = bannerConfig(for: status)
            #expect(config != nil)
            #expect(!config!.icon.isEmpty)
            #expect(!config!.titleKey.isEmpty)
            #expect(!config!.subtitleKey.isEmpty)
            #expect(!config!.actionLabel.isEmpty)
        }
    }
}
