import Foundation
import FirebaseFirestore

struct EmotionModel: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var emotionEmoji: String
    var emotionName: String
    var date: Date
}
