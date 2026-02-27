import Foundation
import FirebaseFirestore

struct OngoingActivity: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var activityId: String
    var startDate: Date
    var endDate: Date
    var createdAt: Date

    /// Populated after fetch, not from Firestore
    var activity: Activity?
    var scheduledTasks: [OngoingActivityTask]?

    var progress: Double {
        guard let tasks = scheduledTasks, !tasks.isEmpty else { return 0 }
        let completed = tasks.filter(\.isCompleted).count
        return Double(completed) / Double(tasks.count)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case activityId
        case startDate
        case endDate
        case createdAt
    }

    static func == (lhs: OngoingActivity, rhs: OngoingActivity) -> Bool {
        lhs.id == rhs.id && lhs.activityId == rhs.activityId
    }
}
