import Foundation
import FirebaseStorage

/// Service for Firebase Storage operations (image upload/download)
@Observable
@MainActor
final class StorageService {

    private let storage = Storage.storage()

    /// Upload image data to Storage and return the download URL
    func uploadImage(path: String, data: Data, contentType: String = "image/jpeg") async throws -> URL {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        return downloadURL
    }

    /// Get download URL for a file at path
    func downloadURL(path: String) async throws -> URL {
        let ref = storage.reference().child(path)
        return try await ref.downloadURL()
    }

    /// Delete a file at path
    func deleteFile(path: String) async throws {
        let ref = storage.reference().child(path)
        try await ref.delete()
    }

    /// Download data from a path
    func downloadData(path: String, maxSize: Int64 = 10 * 1024 * 1024) async throws -> Data {
        let ref = storage.reference().child(path)
        return try await ref.data(maxSize: maxSize)
    }
}
