import Foundation

protocol FirestoreServiceProtocol {
    func getDocument<T: Decodable>(collection: String, id: String) async throws -> T
    func setDocument<T: Encodable>(collection: String, id: String, data: T, merge: Bool) async throws
    func updateDocument(collection: String, id: String, fields: [String: Any]) async throws
    func addDocument<T: Encodable>(collection: String, data: T) async throws -> String
    func deleteDocument(collection: String, id: String) async throws
}
