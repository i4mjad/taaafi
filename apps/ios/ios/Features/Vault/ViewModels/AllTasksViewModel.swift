import Foundation
import FirebaseAuth

@Observable
@MainActor
final class AllTasksViewModel {
    var tasks: [OngoingActivityTask] = []
    var isLoading = false
    var error: String?

    private let activityService: ActivityService

    init(activityService: ActivityService) {
        self.activityService = activityService
    }

    var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    func loadTasks() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        do {
            let ongoingActivities = try await activityService.getOngoingActivities(userId: userId)
            tasks = ongoingActivities.flatMap { $0.scheduledTasks ?? [] }
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
            await loadTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
