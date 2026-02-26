import Testing
@testable import ios

@Suite("AccountStatus")
struct AccountStatusTests {

    @Test("All cases are covered")
    func allCases() {
        #expect(AccountStatus.allCases.count == 7)
    }

    @Test("Raw values match case names")
    func rawValues() {
        #expect(AccountStatus.loading.rawValue == "loading")
        #expect(AccountStatus.ok.rawValue == "ok")
        #expect(AccountStatus.pendingDeletion.rawValue == "pendingDeletion")
    }
}
