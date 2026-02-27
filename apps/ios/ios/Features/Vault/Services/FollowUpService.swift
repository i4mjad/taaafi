import Foundation
import FirebaseFirestore

protocol FollowUpServiceProtocol {
    func getFollowUps(userId: String, startDate: Date, endDate: Date) async throws -> [FollowUpModel]
    func addFollowUp(userId: String, followUp: FollowUpModel) async throws -> String
    func deleteFollowUp(userId: String, followUpId: String) async throws
    func deleteFollowUpsForDate(userId: String, date: Date) async throws
    func listenToFollowUps(userId: String, startDate: Date, endDate: Date) -> AsyncStream<[FollowUpModel]>
}

@Observable
@MainActor
final class FollowUpService: FollowUpServiceProtocol {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    private func collectionPath(userId: String) -> String {
        "users/\(userId)/followUps"
    }

    func getFollowUps(userId: String, startDate: Date, endDate: Date) async throws -> [FollowUpModel] {
        try await firestoreService.getDocuments(
            collection: collectionPath(userId: userId),
            filters: [
                .isGreaterThanOrEqualTo(field: "time", value: Timestamp(date: startDate)),
                .isLessThanOrEqualTo(field: "time", value: Timestamp(date: endDate))
            ],
            orderBy: "time",
            descending: true
        )
    }

    func addFollowUp(userId: String, followUp: FollowUpModel) async throws -> String {
        try await firestoreService.addDocument(
            collection: collectionPath(userId: userId),
            data: followUp
        )
    }

    func deleteFollowUp(userId: String, followUpId: String) async throws {
        try await firestoreService.deleteDocument(
            collection: collectionPath(userId: userId),
            id: followUpId
        )
    }

    func deleteFollowUpsForDate(userId: String, date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let followUps: [FollowUpModel] = try await firestoreService.getDocuments(
            collection: collectionPath(userId: userId),
            filters: [
                .isGreaterThanOrEqualTo(field: "time", value: Timestamp(date: startOfDay)),
                .isLessThan(field: "time", value: Timestamp(date: endOfDay))
            ]
        )

        for followUp in followUps {
            if let id = followUp.id {
                try await firestoreService.deleteDocument(
                    collection: collectionPath(userId: userId),
                    id: id
                )
            }
        }
    }

    func listenToFollowUps(userId: String, startDate: Date, endDate: Date) -> AsyncStream<[FollowUpModel]> {
        firestoreService.listenToCollection(
            collection: collectionPath(userId: userId),
            filters: [
                .isGreaterThanOrEqualTo(field: "time", value: Timestamp(date: startDate)),
                .isLessThanOrEqualTo(field: "time", value: Timestamp(date: endDate))
            ],
            orderBy: "time",
            descending: true
        )
    }
}
