import Foundation
import FirebaseFunctions

/// Service for calling Firebase Cloud Functions
/// Region: us-central1 (matching existing functions config)
@Observable
@MainActor
final class CloudFunctionsService {

    private let functions: Functions

    init() {
        functions = Functions.functions(region: "us-central1")
    }

    /// Call a Cloud Function and decode the response
    func call<T: Decodable>(functionName: String, data: [String: Any]? = nil) async throws -> T {
        let callable = functions.httpsCallable(functionName)
        let result = try await callable.call(data as Any)

        guard let responseData = result.data as? [String: Any] else {
            throw CloudFunctionsError.invalidResponse
        }

        let jsonData = try JSONSerialization.data(withJSONObject: responseData)
        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    /// Call a Cloud Function without expecting a typed response
    func callVoid(functionName: String, data: [String: Any]? = nil) async throws {
        let callable = functions.httpsCallable(functionName)
        _ = try await callable.call(data as Any)
    }

    /// Call a Cloud Function and return raw dictionary response
    func callRaw(functionName: String, data: [String: Any]? = nil) async throws -> [String: Any] {
        let callable = functions.httpsCallable(functionName)
        let result = try await callable.call(data as Any)

        guard let responseData = result.data as? [String: Any] else {
            throw CloudFunctionsError.invalidResponse
        }

        return responseData
    }
}

enum CloudFunctionsError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Cloud Function"
        }
    }
}
