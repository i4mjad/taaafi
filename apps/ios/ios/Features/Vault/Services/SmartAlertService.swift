import Foundation
import FirebaseFirestore

@Observable
@MainActor
final class SmartAlertService {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func getSettings(userId: String) async throws -> SmartAlertSettings {
        let doc: SmartAlertSettings? = try? await firestoreService.getDocument(
            collection: "users/\(userId)/settings",
            id: "smartAlerts"
        )
        return doc ?? .empty
    }

    func saveSettings(userId: String, settings: SmartAlertSettings) async throws {
        try await firestoreService.setDocument(
            collection: "users/\(userId)/settings",
            id: "smartAlerts",
            data: settings
        )
    }

    func checkEligibility(userId: String, followUps: [FollowUpModel]) -> (isEligible: Bool, reason: String?) {
        // Need at least 10 follow-ups for risk hour calculation
        let relapseFollowUps = followUps.filter { $0.type != .none }
        if relapseFollowUps.count < 10 {
            return (false, "need-followups-for-risk-hour:\(10 - relapseFollowUps.count)")
        }

        // Need at least 4 weeks of data for vulnerability patterns
        guard let earliest = followUps.map(\.time).min() else {
            return (false, "need-weeks-for-vulnerability:4")
        }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: earliest, to: Date()).weekOfYear ?? 0
        if weeks < 4 {
            return (false, "need-weeks-for-vulnerability:\(4 - weeks)")
        }

        return (true, nil)
    }
}
