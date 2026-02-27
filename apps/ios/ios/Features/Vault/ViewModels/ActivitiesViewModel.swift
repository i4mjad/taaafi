import Foundation
import FirebaseAuth

@Observable
@MainActor
final class ActivitiesViewModel {
    var todayTasks: [OngoingActivityTask] = []
    var ongoingActivities: [OngoingActivity] = []
    var isLoading = false
    var error: String?

    private let activityService: ActivityService

    init(activityService: ActivityService) {
        self.activityService = activityService
    }

    var completedTasksCount: Int {
        todayTasks.filter(\.isCompleted).count
    }

    var totalTasksCount: Int {
        todayTasks.count
    }

    func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        do {
            todayTasks = try await activityService.getTodayTasks(userId: userId)
            ongoingActivities = try await activityService.getOngoingActivities(userId: userId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func toggleTask(_ task: OngoingActivityTask) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let taskId = task.id,
              let activityId = task.activityId else { return }

        do {
            try await activityService.toggleTaskCompletion(
                userId: userId,
                ongoingActivityId: activityId,
                taskId: taskId,
                isCompleted: !task.isCompleted
            )
            // Refresh
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
