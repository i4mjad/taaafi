import Foundation
import FirebaseAuth

@Observable
@MainActor
final class ActivityOverviewViewModel {
    var activity: Activity?
    var tasks: [ActivityTask] = []
    var isLoading = false
    var isSubscribing = false
    var error: String?

    private let activityService: ActivityService
    private let activityId: String

    init(activityId: String, activityService: ActivityService) {
        self.activityId = activityId
        self.activityService = activityService
    }

    func loadActivity() async {
        isLoading = true
        do {
            activity = try await activityService.getActivity(activityId: activityId)
            tasks = try await activityService.getActivityTasks(activityId: activityId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func subscribe() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSubscribing = true
        do {
            try await activityService.subscribeToActivity(
                userId: userId,
                activityId: activityId,
                tasks: tasks
            )
            // Refresh to update subscriber count
            await loadActivity()
            isSubscribing = false
        } catch {
            self.error = error.localizedDescription
            isSubscribing = false
        }
    }
}
