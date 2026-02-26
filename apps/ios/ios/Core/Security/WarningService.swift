import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Handles warning queries: user warnings, high-priority warnings
/// Ported from: apps/mobile/lib/features/account/application/warning_service.dart
final class WarningService {

    private let db = Firestore.firestore()

    /// Get user's active warnings
    func getUserWarnings(userId: String) async throws -> [Warning] {
        let snapshot = try await db.collection("warnings")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "issuedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { Warning.fromFirestore($0) }
    }

    /// Get high-priority warnings for current user
    func getCurrentUserHighPriorityWarnings() async throws -> [Warning] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }

        let warnings = try await getUserWarnings(userId: uid)
        return warnings.filter {
            $0.severity == .high || $0.severity == .critical
        }
    }
}
