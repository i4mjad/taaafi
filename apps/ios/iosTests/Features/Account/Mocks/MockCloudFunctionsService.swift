import Foundation
@testable import ios

final class MockCloudFunctionsService: CloudFunctionsServiceProtocol {
    var callRawResult: [String: Any] = [:]
    var callRawError: Error?
    var callRawCallCount = 0
    var lastCalledFunction: String?

    func call<T: Decodable>(functionName: String, data: [String: Any]?) async throws -> T {
        fatalError("Not implemented in mock")
    }

    func callVoid(functionName: String, data: [String: Any]?) async throws {
        lastCalledFunction = functionName
    }

    func callRaw(functionName: String, data: [String: Any]?) async throws -> [String: Any] {
        callRawCallCount += 1
        lastCalledFunction = functionName
        if let error = callRawError { throw error }
        return callRawResult
    }
}
