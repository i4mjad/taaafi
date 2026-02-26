import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Syncs Firebase Auth email to Firestore and handles Apple users without email
/// Ported from: apps/mobile/lib/core/services/email_sync_service.dart
@Observable
@MainActor
final class EmailSyncService {

    private let db = Firestore.firestore()

    /// Syncs the user's Firebase Auth email to their Firestore document if different
    func syncUserEmailIfNeeded() async {
        guard let currentUser = Auth.auth().currentUser,
              let firebaseEmail = currentUser.email, !firebaseEmail.isEmpty else {
            return
        }

        let uid = currentUser.uid
        let docRef = db.collection("users").document(uid)

        do {
            let snapshot = try await docRef.getDocument()
            guard snapshot.exists, let data = snapshot.data() else { return }

            let firestoreEmail = data["email"] as? String

            if firestoreEmail != firebaseEmail {
                try await docRef.updateData([
                    "email": firebaseEmail,
                    "lastEmailSync": FieldValue.serverTimestamp(),
                ])
            }
        } catch {
            print("[EmailSyncService] Email sync failed: \(error.localizedDescription)")
        }
    }

    /// Checks if the user is an Apple user without an email address
    func isAppleUserWithoutEmail() -> Bool {
        guard let user = Auth.auth().currentUser else { return false }

        let hasAppleProvider = user.providerData.contains { $0.providerID == "apple.com" }
        guard hasAppleProvider else { return false }

        return user.email == nil || user.email?.isEmpty == true
    }

    /// Gets the user's auth provider IDs
    func getUserProviders() -> [String] {
        guard let user = Auth.auth().currentUser else { return [] }
        return user.providerData.map(\.providerID)
    }

    /// Checks if user should be prompted for email collection (legacy Apple users)
    func shouldPromptForEmailCollection() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        guard isAppleUserWithoutEmail() else { return false }

        do {
            let doc = try await db.collection("users").document(user.uid).getDocument()
            guard doc.exists, let data = doc.data() else { return false }
            return data["emailCollectionPrompted"] as? Bool != true
        } catch {
            return false
        }
    }

    /// Marks that the user has been prompted for email collection
    func markEmailCollectionPrompted() async {
        guard let user = Auth.auth().currentUser else { return }
        try? await db.collection("users").document(user.uid).updateData([
            "emailCollectionPrompted": true,
            "emailCollectionPromptedAt": FieldValue.serverTimestamp(),
        ])
    }
}
