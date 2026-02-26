import Foundation
import FirebaseFirestore

/// Protocol for testability
protocol UserDocumentServiceProtocol {
    var userDocument: UserDocument? { get }
    var isLoading: Bool { get }
    var accountStatus: AccountStatus { get }
    func startListening(userId: String)
    func stopListening()
    func createUserDocument(_ doc: UserDocument, userId: String) async throws
    func updateUserDocument(userId: String, fields: [String: Any]) async throws
    func documentExists(userId: String) async -> Bool
}

/// Manages the current user's Firestore document with real-time listening
@Observable
@MainActor
final class UserDocumentService: UserDocumentServiceProtocol {

    private(set) var userDocument: UserDocument?
    private(set) var isLoading = true

    private let firestoreService: FirestoreService
    private var listenerTask: Task<Void, Never>?

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - Account Status

    var accountStatus: AccountStatus {
        if isLoading {
            return .loading
        }

        guard let doc = userDocument else {
            return .needCompleteRegistration
        }

        if doc.isRequestedToBeDeleted == true {
            return .pendingDeletion
        }

        if doc.hasMissingData || doc.isLegacyDocument {
            return .needConfirmDetails
        }

        return .ok
    }

    // MARK: - Real-time Listener

    func startListening(userId: String) {
        stopListening()
        isLoading = true

        let stream: AsyncStream<UserDocument?> = firestoreService.listenToDocument(
            collection: "users",
            id: userId
        )

        listenerTask = Task { [weak self] in
            for await document in stream {
                guard !Task.isCancelled else { return }
                self?.userDocument = document
                self?.isLoading = false
            }
        }
    }

    func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
        userDocument = nil
        isLoading = true
    }

    // MARK: - CRUD

    func createUserDocument(_ doc: UserDocument, userId: String) async throws {
        try await firestoreService.setDocument(
            collection: "users",
            id: userId,
            data: doc,
            merge: false
        )
    }

    func updateUserDocument(userId: String, fields: [String: Any]) async throws {
        try await firestoreService.updateDocument(
            collection: "users",
            id: userId,
            fields: fields
        )
    }

    func documentExists(userId: String) async -> Bool {
        do {
            let _: UserDocument = try await firestoreService.getDocument(
                collection: "users",
                id: userId
            )
            return true
        } catch {
            return false
        }
    }
}
