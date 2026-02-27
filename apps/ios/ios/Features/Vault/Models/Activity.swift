import Foundation
import FirebaseFirestore

struct Activity: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var difficulty: ActivityDifficulty
    var subscriberCount: Int
    var tasks: [ActivityTask]?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "activityName"
        case description = "activityDescription"
        case difficulty = "activityDifficulty"
        case subscriberCount
        case tasks
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
}
