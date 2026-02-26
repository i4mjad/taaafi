import SwiftUI

@Observable
@MainActor
final class AccountDeletionManager {
    private let firestoreService: FirestoreService

    private(set) var requestedAt: Date?
    private(set) var scheduledDeletionDate: Date?
    private(set) var isLoading = false
    private(set) var isCancelling = false
    private(set) var error: Error?

    nonisolated static let deletionDelayDays = 30
    private static let collection = "accountDeleteRequests"

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func fetchDeletionDate(userId: String) async {
        isLoading = true
        error = nil

        do {
            let request: DeletionRequest = try await firestoreService.getDocument(
                collection: Self.collection,
                id: userId
            )
            requestedAt = request.requestedAt
            scheduledDeletionDate = Self.computeScheduledDate(from: request.requestedAt)
        } catch {
            self.error = error
            requestedAt = nil
            scheduledDeletionDate = nil
        }

        isLoading = false
    }

    func cancelDeletion(userId: String) async -> Bool {
        isCancelling = true
        error = nil

        do {
            try await firestoreService.updateDocument(
                collection: Self.collection,
                id: userId,
                fields: ["status": "cancelled"]
            )
            isCancelling = false
            requestedAt = nil
            scheduledDeletionDate = nil
            return true
        } catch {
            self.error = error
            isCancelling = false
            return false
        }
    }

    nonisolated static func computeScheduledDate(from requestedAt: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: deletionDelayDays, to: requestedAt) ?? requestedAt
    }

    var formattedDeletionDate: String? {
        guard let scheduledDeletionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: scheduledDeletionDate)
    }
}

private struct DeletionRequest: Codable {
    let requestedAt: Date
    let status: String?
}
