import Foundation
import FirebaseFirestore

/// Queries the features collection for active app features
/// Ported from: apps/mobile/lib/features/account/application/app_feature_service.dart
final class AppFeatureService {

    private let db = Firestore.firestore()

    /// Get all active app features
    func getAppFeatures() async throws -> [AppFeature] {
        let snapshot = try await db.collection("features")
            .whereField("isActive", isEqualTo: true)
            .order(by: "category")
            .order(by: "nameEn")
            .getDocuments()

        return snapshot.documents.compactMap { AppFeature.fromFirestore($0) }
    }

    /// Get specific feature by unique name
    func getFeatureByUniqueName(_ uniqueName: String) async throws -> AppFeature? {
        let snapshot = try await db.collection("features")
            .whereField("uniqueName", isEqualTo: uniqueName)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { AppFeature.fromFirestore($0) }
    }
}
