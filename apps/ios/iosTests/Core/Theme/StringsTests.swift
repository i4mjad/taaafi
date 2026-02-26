import Testing
@testable import ios

@Suite("Strings")
struct StringsTests {

    // MARK: - Tab Keys

    @Test("tab keys are non-empty")
    func tabKeysNonEmpty() {
        #expect(!Strings.Tab.home.isEmpty)
        #expect(!Strings.Tab.vault.isEmpty)
        #expect(!Strings.Tab.guard.isEmpty)
        #expect(!Strings.Tab.community.isEmpty)
        #expect(!Strings.Tab.account.isEmpty)
    }

    // MARK: - Guard Keys

    @Test("guard keys are non-empty")
    func guardKeysNonEmpty() {
        #expect(!Strings.Guard.title.isEmpty)
        #expect(!Strings.Guard.today.isEmpty)
        #expect(!Strings.Guard.yesterday.isEmpty)
        #expect(!Strings.Guard.screenTimePermission.isEmpty)
        #expect(!Strings.Guard.screenTimeDescription.isEmpty)
        #expect(!Strings.Guard.enableAccess.isEmpty)
        #expect(!Strings.Guard.selectDate.isEmpty)
        #expect(!Strings.Guard.done.isEmpty)
        #expect(!Strings.Guard.settings.isEmpty)
        #expect(!Strings.Guard.safe.isEmpty)
        #expect(!Strings.Guard.neutral.isEmpty)
        #expect(!Strings.Guard.threat.isEmpty)
        #expect(!Strings.Guard.categoryClassifications.isEmpty)
        #expect(!Strings.Guard.categoryFooter.isEmpty)
    }

    // MARK: - Common Keys

    @Test("common keys are non-empty")
    func commonKeysNonEmpty() {
        #expect(!Strings.Common.loading.isEmpty)
        #expect(!Strings.Common.accessRestricted.isEmpty)
        #expect(!Strings.Common.accessRestrictedMessage.isEmpty)
    }
}
