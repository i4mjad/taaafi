import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class DataRestorationViewModel {
    var isAnalyzing = true
    var isRestoring = false
    var needsRestoration = false
    var migrationStatus: String?
    var error: String?

    private let userDocumentService: UserDocumentServiceProtocol

    init(userDocumentService: UserDocumentServiceProtocol) {
        self.userDocumentService = userDocumentService
    }

    func analyzeMigrationStatus() async {
        isAnalyzing = true

        // Check if user document has legacy data fields
        let doc = userDocumentService.userDocument
        let hasLegacyData = doc?.hasLegacyData == true
        let migrationCompleted = doc?.migrationCompleted == true

        needsRestoration = hasLegacyData && !migrationCompleted

        if needsRestoration {
            migrationStatus = String(localized: "vault.dataRestoration.legacyDataFound")
        }

        isAnalyzing = false
    }

    func performRestoration() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isRestoring = true
        error = nil

        do {
            try await userDocumentService.updateUserDocument(
                userId: userId,
                fields: ["migrationCompleted": true]
            )
            needsRestoration = false
            isRestoring = false
        } catch {
            self.error = error.localizedDescription
            isRestoring = false
        }
    }
}
