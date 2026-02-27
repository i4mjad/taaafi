import Foundation
import FirebaseFirestore

protocol EmotionServiceProtocol {
    func getEmotions(userId: String, startDate: Date, endDate: Date) async throws -> [EmotionModel]
    func addEmotion(userId: String, emotion: EmotionModel) async throws -> String
    func deleteEmotion(userId: String, emotionId: String) async throws
    func listenToEmotions(userId: String, date: Date) -> AsyncStream<[EmotionModel]>
}

@Observable
@MainActor
final class EmotionService: EmotionServiceProtocol {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    private func collectionPath(userId: String) -> String {
        "users/\(userId)/emotions"
    }

    func getEmotions(userId: String, startDate: Date, endDate: Date) async throws -> [EmotionModel] {
        try await firestoreService.getDocuments(
            collection: collectionPath(userId: userId),
            filters: [
                .isGreaterThanOrEqualTo(field: "date", value: Timestamp(date: startDate)),
                .isLessThanOrEqualTo(field: "date", value: Timestamp(date: endDate))
            ],
            orderBy: "date",
            descending: true
        )
    }

    func addEmotion(userId: String, emotion: EmotionModel) async throws -> String {
        try await firestoreService.addDocument(
            collection: collectionPath(userId: userId),
            data: emotion
        )
    }

    func deleteEmotion(userId: String, emotionId: String) async throws {
        try await firestoreService.deleteDocument(
            collection: collectionPath(userId: userId),
            id: emotionId
        )
    }

    func listenToEmotions(userId: String, date: Date) -> AsyncStream<[EmotionModel]> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return firestoreService.listenToCollection(
            collection: collectionPath(userId: userId),
            filters: [
                .isGreaterThanOrEqualTo(field: "date", value: Timestamp(date: startOfDay)),
                .isLessThan(field: "date", value: Timestamp(date: endOfDay))
            ],
            orderBy: "date",
            descending: true
        )
    }
}
