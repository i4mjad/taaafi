import Foundation

@Observable
@MainActor
final class ResetDataViewModel {
    private let userDocumentService: UserDocumentServiceProtocol
    private let userId: String

    var selectedDate: Date
    var resetToToday: Bool = false
    var deleteFollowUps: Bool = false
    var deleteEmotions: Bool = false

    private(set) var isSubmitting = false
    private(set) var error: Error?

    init(userFirstDate: Date?, userId: String, userDocumentService: UserDocumentServiceProtocol) {
        self.userDocumentService = userDocumentService
        self.userId = userId
        self.selectedDate = userFirstDate ?? Date()
    }

    func confirm() async -> Bool {
        isSubmitting = true
        error = nil

        var fields: [String: Any] = [:]

        if resetToToday {
            fields["userFirstDate"] = Date()
        } else {
            fields["userFirstDate"] = selectedDate
        }

        // Note: Actual subcollection deletion would require Cloud Functions.
        // For now, we update the user document date and mark flags.
        if deleteFollowUps {
            fields["userRelapses"] = [String]()
            fields["userMasturbatingWithoutWatching"] = [String]()
            fields["userWatchingWithoutMasturbating"] = [String]()
        }

        do {
            try await userDocumentService.updateUserDocument(userId: userId, fields: fields)
            isSubmitting = false
            return true
        } catch {
            self.error = error
            isSubmitting = false
            return false
        }
    }
}
