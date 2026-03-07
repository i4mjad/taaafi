import Foundation
@testable import ios

final class MockUserDocumentService: UserDocumentServiceProtocol {
    var userDocument: UserDocument?
    var isLoading = false
    var accountStatus: AccountStatus = .ok

    var updateCallCount = 0
    var lastUpdatedFields: [String: Any]?
    var updateError: Error?

    func startListening(userId: String) {}
    func stopListening() {}

    func createUserDocument(_ doc: UserDocument, userId: String) async throws {}

    func updateUserDocument(userId: String, fields: [String: Any]) async throws {
        updateCallCount += 1
        lastUpdatedFields = fields
        if let error = updateError { throw error }
    }

    func documentExists(userId: String) async -> Bool { userDocument != nil }
}
