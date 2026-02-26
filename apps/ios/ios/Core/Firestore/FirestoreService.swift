import Foundation
import FirebaseFirestore

/// Generic Firestore CRUD service with real-time listeners
/// Ported from various datasources across apps/mobile/lib/features/
@Observable
@MainActor
final class FirestoreService {

    private let db = Firestore.firestore()

    // MARK: - Read

    func getDocument<T: Decodable>(collection: String, id: String) async throws -> T {
        let snapshot = try await db.collection(collection).document(id).getDocument()
        guard snapshot.exists else {
            throw FirestoreServiceError.documentNotFound(collection: collection, id: id)
        }
        return try snapshot.data(as: T.self)
    }

    func getDocuments<T: Decodable>(
        collection: String,
        filters: [FirestoreFilter] = [],
        orderBy: String? = nil,
        descending: Bool = false,
        limit: Int? = nil
    ) async throws -> [T] {
        var query: Query = db.collection(collection)

        for filter in filters {
            switch filter {
            case .isEqualTo(let field, let value):
                query = query.whereField(field, isEqualTo: value)
            case .isNotEqualTo(let field, let value):
                query = query.whereField(field, isNotEqualTo: value)
            case .isLessThan(let field, let value):
                query = query.whereField(field, isLessThan: value)
            case .isGreaterThan(let field, let value):
                query = query.whereField(field, isGreaterThan: value)
            case .arrayContains(let field, let value):
                query = query.whereField(field, arrayContains: value)
            case .arrayContainsAny(let field, let values):
                query = query.whereField(field, arrayContainsAny: values)
            case .isIn(let field, let values):
                query = query.whereField(field, in: values)
            }
        }

        if let orderBy {
            query = query.order(by: orderBy, descending: descending)
        }

        if let limit {
            query = query.limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }

    // MARK: - Write

    func setDocument<T: Encodable>(collection: String, id: String, data: T, merge: Bool = false) async throws {
        try db.collection(collection).document(id).setData(from: data, merge: merge)
    }

    func updateDocument(collection: String, id: String, fields: [String: Any]) async throws {
        try await db.collection(collection).document(id).updateData(fields)
    }

    func deleteDocument(collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    // MARK: - Real-time Listeners

    func listenToDocument<T: Decodable>(collection: String, id: String) -> AsyncStream<T?> {
        AsyncStream { continuation in
            let listener = db.collection(collection).document(id)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        print("[FirestoreService] Listen error: \(error.localizedDescription)")
                        continuation.yield(nil)
                        return
                    }
                    guard let snapshot, snapshot.exists else {
                        continuation.yield(nil)
                        return
                    }
                    do {
                        let decoded = try snapshot.data(as: T.self)
                        continuation.yield(decoded)
                    } catch {
                        print("[FirestoreService] Decode error: \(error.localizedDescription)")
                        continuation.yield(nil)
                    }
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    func listenToCollection<T: Decodable>(
        collection: String,
        filters: [FirestoreFilter] = [],
        orderBy: String? = nil,
        descending: Bool = false,
        limit: Int? = nil
    ) -> AsyncStream<[T]> {
        AsyncStream { continuation in
            var query: Query = db.collection(collection)

            for filter in filters {
                switch filter {
                case .isEqualTo(let field, let value):
                    query = query.whereField(field, isEqualTo: value)
                case .isNotEqualTo(let field, let value):
                    query = query.whereField(field, isNotEqualTo: value)
                case .isLessThan(let field, let value):
                    query = query.whereField(field, isLessThan: value)
                case .isGreaterThan(let field, let value):
                    query = query.whereField(field, isGreaterThan: value)
                case .arrayContains(let field, let value):
                    query = query.whereField(field, arrayContains: value)
                case .arrayContainsAny(let field, let values):
                    query = query.whereField(field, arrayContainsAny: values)
                case .isIn(let field, let values):
                    query = query.whereField(field, in: values)
                }
            }

            if let orderBy {
                query = query.order(by: orderBy, descending: descending)
            }

            if let limit {
                query = query.limit(to: limit)
            }

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    print("[FirestoreService] Collection listen error: \(error.localizedDescription)")
                    continuation.yield([])
                    return
                }
                guard let snapshot else {
                    continuation.yield([])
                    return
                }
                let results: [T] = snapshot.documents.compactMap { doc in
                    try? doc.data(as: T.self)
                }
                continuation.yield(results)
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Direct Firestore Access (for FieldValue operations)

    var firestore: Firestore { db }
}

// MARK: - Filter Types

enum FirestoreFilter {
    case isEqualTo(field: String, value: Any)
    case isNotEqualTo(field: String, value: Any)
    case isLessThan(field: String, value: Any)
    case isGreaterThan(field: String, value: Any)
    case arrayContains(field: String, value: Any)
    case arrayContainsAny(field: String, values: [Any])
    case isIn(field: String, values: [Any])
}

// MARK: - Errors

enum FirestoreServiceError: LocalizedError {
    case documentNotFound(collection: String, id: String)

    var errorDescription: String? {
        switch self {
        case .documentNotFound(let collection, let id):
            return "Document not found: \(collection)/\(id)"
        }
    }
}
