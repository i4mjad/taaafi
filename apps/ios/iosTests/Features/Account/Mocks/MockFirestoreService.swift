import Foundation
@testable import ios

final class MockFirestoreService: FirestoreServiceProtocol {
    var addDocumentResult: String = "mock-doc-id"
    var addDocumentError: Error?
    var addDocumentCallCount = 0
    var lastAddedCollection: String?

    var updateDocumentError: Error?
    var updateDocumentCallCount = 0
    var lastUpdatedFields: [String: Any]?

    func getDocument<T: Decodable>(collection: String, id: String) async throws -> T {
        fatalError("Not implemented in mock")
    }

    func setDocument<T: Encodable>(collection: String, id: String, data: T, merge: Bool) async throws {}

    func updateDocument(collection: String, id: String, fields: [String: Any]) async throws {
        updateDocumentCallCount += 1
        lastUpdatedFields = fields
        if let error = updateDocumentError { throw error }
    }

    func addDocument<T: Encodable>(collection: String, data: T) async throws -> String {
        addDocumentCallCount += 1
        lastAddedCollection = collection
        if let error = addDocumentError { throw error }
        return addDocumentResult
    }

    func deleteDocument(collection: String, id: String) async throws {}
}
