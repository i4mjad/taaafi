import Testing
import Foundation
@testable import ios

@Suite("AccountDeletionManager")
struct AccountDeletionManagerTests {

    @Test("Scheduled date is 30 days after request")
    func scheduledDate30Days() {
        let requestDate = Date(timeIntervalSince1970: 1_700_000_000)
        let scheduled = AccountDeletionManager.computeScheduledDate(from: requestDate)
        let days = Calendar.current.dateComponents([.day], from: requestDate, to: scheduled).day
        #expect(days == 30)
    }

    @Test("Scheduled date preserves time of day")
    func preservesTime() {
        let requestDate = Date(timeIntervalSince1970: 1_700_000_000)
        let scheduled = AccountDeletionManager.computeScheduledDate(from: requestDate)

        let requestHour = Calendar.current.component(.hour, from: requestDate)
        let scheduledHour = Calendar.current.component(.hour, from: scheduled)
        #expect(requestHour == scheduledHour)
    }

    @Test("Deletion delay constant is 30")
    func delayConstant() {
        #expect(AccountDeletionManager.deletionDelayDays == 30)
    }
}
