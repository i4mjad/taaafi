import Foundation
import FirebaseAuth

@Observable
@MainActor
final class DayOverviewViewModel {
    let date: Date
    var followUps: [FollowUpModel] = []
    var emotions: [EmotionModel] = []
    var isLoading = false

    private let followUpService: FollowUpService
    private let emotionService: EmotionService

    init(date: Date, followUpService: FollowUpService, emotionService: EmotionService) {
        self.date = date
        self.followUpService = followUpService
        self.emotionService = emotionService
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: date)
    }

    func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            followUps = try await followUpService.getFollowUps(
                userId: userId,
                startDate: startOfDay,
                endDate: endOfDay
            )
            emotions = try await emotionService.getEmotions(
                userId: userId,
                startDate: startOfDay,
                endDate: endOfDay
            )
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    func deleteFollowUp(_ followUp: FollowUpModel) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let followUpId = followUp.id else { return }
        do {
            try await followUpService.deleteFollowUp(userId: userId, followUpId: followUpId)
            followUps.removeAll { $0.id == followUpId }
        } catch {
            print("[DayOverview] Delete error: \(error.localizedDescription)")
        }
    }

    func deleteEmotion(_ emotion: EmotionModel) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let emotionId = emotion.id else { return }
        do {
            try await emotionService.deleteEmotion(userId: userId, emotionId: emotionId)
            emotions.removeAll { $0.id == emotionId }
        } catch {
            print("[DayOverview] Delete emotion error: \(error.localizedDescription)")
        }
    }
}
