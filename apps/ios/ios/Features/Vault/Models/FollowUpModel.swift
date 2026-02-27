import Foundation
import FirebaseFirestore

struct FollowUpModel: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var type: FollowUpType
    var time: Date
    var triggers: [String]

    static func == (lhs: FollowUpModel, rhs: FollowUpModel) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type && lhs.time == rhs.time && lhs.triggers == rhs.triggers
    }
}
