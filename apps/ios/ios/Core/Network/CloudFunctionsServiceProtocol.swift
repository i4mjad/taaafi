import Foundation

protocol CloudFunctionsServiceProtocol {
    func call<T: Decodable>(functionName: String, data: [String: Any]?) async throws -> T
    func callVoid(functionName: String, data: [String: Any]?) async throws
    func callRaw(functionName: String, data: [String: Any]?) async throws -> [String: Any]
}
