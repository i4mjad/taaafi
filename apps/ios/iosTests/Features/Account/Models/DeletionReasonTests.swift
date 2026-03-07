import Testing
@testable import ios

@Suite("DeletionReason")
struct DeletionReasonTests {

    @Test("All 12 reasons exist")
    func allReasonsCount() {
        #expect(DeletionReason.allReasons.count == 12)
    }

    @Test("All reason IDs are unique")
    func uniqueIds() {
        let ids = DeletionReason.allReasons.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("findById returns correct reason")
    func findByIdWorks() {
        let reason = DeletionReason.findById("privacy_concerns")
        #expect(reason != nil)
        #expect(reason?.id == "privacy_concerns")
        #expect(reason?.category == .privacy)
    }

    @Test("findById returns nil for unknown ID")
    func findByIdUnknown() {
        #expect(DeletionReason.findById("nonexistent") == nil)
    }

    @Test("requiresDetails is true for technical_issues, missing_features, content_inappropriate, other")
    func requiresDetailsFlags() {
        let detailIds = DeletionReason.allReasons.filter(\.requiresDetails).map(\.id)
        #expect(detailIds.contains("technical_issues"))
        #expect(detailIds.contains("missing_features"))
        #expect(detailIds.contains("content_inappropriate"))
        #expect(detailIds.contains("other"))
        #expect(detailIds.count == 4)
    }

    @Test("Every reason has a non-empty translation key")
    func translationKeysNotEmpty() {
        for reason in DeletionReason.allReasons {
            #expect(!reason.translationKey.isEmpty)
        }
    }
}
