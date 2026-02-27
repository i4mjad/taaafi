import Foundation
import FirebaseFirestore

struct OngoingActivityTask: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var taskId: String
    var scheduledDate: Date
    var isCompleted: Bool

    /// Populated after fetch, not from Firestore
    var task: ActivityTask?
    var activityId: String?
}
