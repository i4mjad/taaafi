import Testing
import Foundation
@testable import ios

@Suite("DeleteAccountViewModel")
struct DeleteAccountViewModelTests {

    @MainActor
    private func makeVM(
        cloudFunctions: MockCloudFunctionsService = MockCloudFunctionsService(),
        firestore: MockFirestoreService = MockFirestoreService()
    ) -> (DeleteAccountViewModel, MockCloudFunctionsService, MockFirestoreService) {
        let vm = DeleteAccountViewModel(
            cloudFunctionsService: cloudFunctions,
            firestoreService: firestore,
            authService: AuthService(),
            userId: "u1",
            userEmail: "test@test.com",
            userName: "Test"
        )
        return (vm, cloudFunctions, firestore)
    }

    @Test("Initial state has no reason selected")
    @MainActor
    func initialState() {
        let (vm, _, _) = makeVM()
        #expect(vm.selectedReasonId == nil)
        #expect(vm.canSubmit == false)
        #expect(vm.hasClaimedReward == false)
        #expect(vm.hasSkippedOffer == false)
    }

    @Test("selectReason sets the reason ID")
    @MainActor
    func selectReason() {
        let (vm, _, _) = makeVM()
        vm.selectReason("privacy_concerns")
        #expect(vm.selectedReasonId == "privacy_concerns")
        #expect(vm.canSubmit == true)
    }

    @Test("showDetails is true for reasons requiring details")
    @MainActor
    func showDetailsForTechnicalIssues() {
        let (vm, _, _) = makeVM()
        vm.selectReason("technical_issues")
        #expect(vm.showDetails == true)
    }

    @Test("showDetails is false for reasons not requiring details")
    @MainActor
    func noDetailsForPrivacyConcerns() {
        let (vm, _, _) = makeVM()
        vm.selectReason("privacy_concerns")
        #expect(vm.showDetails == false)
    }

    @Test("skipRetentionOffer sets flag")
    @MainActor
    func skipOffer() {
        let (vm, _, _) = makeVM()
        vm.skipRetentionOffer()
        #expect(vm.hasSkippedOffer == true)
    }

    @Test("shouldShowRetentionOffer returns true when eligible")
    @MainActor
    func retentionOfferEligible() {
        let (vm, _, _) = makeVM()
        #expect(vm.shouldShowRetentionOffer(hasActiveSubscription: false) == true)
    }

    @Test("shouldShowRetentionOffer returns false with subscription")
    @MainActor
    func retentionOfferWithSubscription() {
        let (vm, _, _) = makeVM()
        #expect(vm.shouldShowRetentionOffer(hasActiveSubscription: true) == false)
    }

    @Test("checkRetentionRewardStatus calls cloud function")
    @MainActor
    func checkRetention() async {
        let mock = MockCloudFunctionsService()
        mock.callRawResult = ["hasClaimed": false]
        let (vm, _, _) = makeVM(cloudFunctions: mock)

        await vm.checkRetentionRewardStatus()

        #expect(mock.callRawCallCount == 1)
        #expect(mock.lastCalledFunction == "checkRetentionRewardStatus")
        #expect(vm.hasClaimedReward == false)
    }

    @Test("submitDeletionRequest creates document and updates user")
    @MainActor
    func submitDeletion() async {
        let firestore = MockFirestoreService()
        let (vm, _, _) = makeVM(firestore: firestore)
        vm.selectReason("privacy_concerns")

        let result = await vm.submitDeletionRequest()

        #expect(result == true)
        #expect(firestore.addDocumentCallCount == 1)
        #expect(firestore.lastAddedCollection == "accountDeleteRequests")
        #expect(firestore.updateDocumentCallCount == 1)
    }

    @Test("submitDeletionRequest fails without reason")
    @MainActor
    func submitWithoutReason() async {
        let (vm, _, _) = makeVM()
        let result = await vm.submitDeletionRequest()
        #expect(result == false)
    }
}
