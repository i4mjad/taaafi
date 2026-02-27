import Foundation
import FirebaseFirestore

struct ActivityTask: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var frequency: TaskFrequency

    enum CodingKeys: String, CodingKey {
        case id
        case name = "taskName"
        case description = "taskDescription"
        case frequency = "taskFrequency"
    }
}
