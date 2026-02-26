import Foundation
import FirebaseFirestore

struct UserDocument: Codable, Equatable, Identifiable {
    @DocumentID var id: String?
    var devicesIds: [String]?
    var displayName: String?
    var email: String?
    var gender: String?
    var locale: String?
    var dayOfBirth: Date?
    var userFirstDate: Date?
    var role: String?
    var messagingToken: String?

    var userRelapses: [String]?
    var userMasturbatingWithoutWatching: [String]?
    var userWatchingWithoutMasturbating: [String]?

    var isPlusUser: Bool?
    var lastPlusCheck: Date?

    var isRequestedToBeDeleted: Bool?
    var hasCheckedForDataLoss: Bool?

    /// Checks if document has missing required fields (legacy users)
    var hasMissingData: Bool {
        displayName == nil || displayName?.isEmpty == true ||
        email == nil || email?.isEmpty == true ||
        gender == nil || gender?.isEmpty == true ||
        locale == nil || locale?.isEmpty == true ||
        dayOfBirth == nil
    }

    /// Checks if this is a legacy document format
    var isLegacyDocument: Bool {
        hasMissingData || userFirstDate == nil
    }
}
