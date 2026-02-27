import Foundation
import FirebaseAuth

@Observable
@MainActor
final class OngoingActivityViewModel {
    var ongoingActivity: OngoingActivity?
    var activity: Activity?
    var tasks: [OngoingActivityTask] = []
    var isLoading = false
    var error: String?

    private let activityService: ActivityService
    private let ongoingActivityId: String

    init(ongoingActivityId: String, activityService: ActivityService) {
        self.ongoingActivityId = ongoingActivityId
        self.activityService = activityService
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        do {
            let allOngoing = try await activityService.getOngoingActivities(userId: userId)
            ongoingActivity = allOngoing.first { $0.id == ongoingActivityId }
            tasks = ongoingActivity?.scheduledTasks ?? []
            activity = ongoingActivity?.activity
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func toggleTask(_ task: OngoingActivityTask) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let taskId = task.id else { return }

        do {
            try await activityService.toggleTaskCompletion(
                userId: userId,
                ongoingActivityId: ongoingActivityId,
                taskId: taskId,
                isCompleted: !task.isCompleted
            )
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func unsubscribe() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            try await activityService.unsubscribeFromActivity(
                userId: userId,
                ongoingActivityId: ongoingActivityId
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
