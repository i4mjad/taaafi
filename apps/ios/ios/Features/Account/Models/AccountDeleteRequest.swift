import Foundation
import FirebaseFirestore

struct AccountDeleteRequest: Codable {
    var userId: String
    var userEmail: String
    var userName: String
    @ServerTimestamp var requestedAt: Date?
    var reasonId: String
    var reasonDetails: String?
    var reasonCategory: String
    var isCanceled: Bool
    var isProcessed: Bool
}
