import Foundation

@Observable
@MainActor
final class DeleteAccountViewModel {
    private let cloudFunctionsService: CloudFunctionsServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    private let authService: AuthService
    private let userId: String
    private let userEmail: String
    private let userName: String

    // Retention
    private(set) var isCheckingRetention = false
    private(set) var hasClaimedReward = false
    var hasSkippedOffer = false
    private(set) var isClaimingReward = false

    // Deletion
    var selectedReasonId: String?
    var detailsText: String = ""
    private(set) var isSubmitting = false
    private(set) var error: Error?

    var showDetails: Bool {
        guard let id = selectedReasonId else { return false }
        return DeletionReason.findById(id)?.requiresDetails ?? false
    }

    var canSubmit: Bool {
        selectedReasonId != nil && !isSubmitting
    }

    init(
        cloudFunctionsService: CloudFunctionsServiceProtocol,
        firestoreService: FirestoreServiceProtocol,
        authService: AuthService,
        userId: String,
        userEmail: String,
        userName: String
    ) {
        self.cloudFunctionsService = cloudFunctionsService
        self.firestoreService = firestoreService
        self.authService = authService
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
    }

    // MARK: - Retention

    func checkRetentionRewardStatus() async {
        isCheckingRetention = true
        do {
            let result = try await cloudFunctionsService.callRaw(functionName: "checkRetentionRewardStatus", data: nil)
            hasClaimedReward = result["hasClaimed"] as? Bool ?? false
        } catch {
            // If check fails, just proceed without retention offer
        }
        isCheckingRetention = false
    }

    func claimRetentionReward() async {
        isClaimingReward = true
        do {
            _ = try await cloudFunctionsService.callRaw(functionName: "claimRetentionReward", data: nil)
            hasClaimedReward = true
        } catch {
            self.error = error
        }
        isClaimingReward = false
    }

    func skipRetentionOffer() {
        hasSkippedOffer = true
    }

    func shouldShowRetentionOffer(hasActiveSubscription: Bool) -> Bool {
        !hasClaimedReward && !hasSkippedOffer && !hasActiveSubscription && !isCheckingRetention
    }

    // MARK: - Reason Selection

    func selectReason(_ reasonId: String) {
        selectedReasonId = reasonId
        if !(DeletionReason.findById(reasonId)?.requiresDetails ?? false) {
            detailsText = ""
        }
    }

    // MARK: - Submit Deletion

    func submitDeletionRequest() async -> Bool {
        guard let reasonId = selectedReasonId else { return false }
        guard let reason = DeletionReason.findById(reasonId) else { return false }

        isSubmitting = true
        error = nil

        let request = AccountDeleteRequest(
            userId: userId,
            userEmail: userEmail,
            userName: userName,
            reasonId: reasonId,
            reasonDetails: detailsText.isEmpty ? nil : detailsText,
            reasonCategory: reason.category.rawValue,
            isCanceled: false,
            isProcessed: false
        )

        do {
            _ = try await firestoreService.addDocument(collection: "accountDeleteRequests", data: request)
            try await firestoreService.updateDocument(
                collection: "users",
                id: userId,
                fields: ["isRequestedToBeDeleted": true]
            )

            try? authService.signOut()
            isSubmitting = false
            return true
        } catch {
            self.error = error
            isSubmitting = false
            return false
        }
    }
}
