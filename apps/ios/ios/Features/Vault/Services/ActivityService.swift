import Foundation
import FirebaseFirestore

protocol ActivityServiceProtocol {
    func getActivities() async throws -> [Activity]
    func getActivity(activityId: String) async throws -> Activity
    func getActivityTasks(activityId: String) async throws -> [ActivityTask]
    func getOngoingActivities(userId: String) async throws -> [OngoingActivity]
    func subscribeToActivity(userId: String, activityId: String, tasks: [ActivityTask]) async throws
    func unsubscribeFromActivity(userId: String, ongoingActivityId: String) async throws
    func toggleTaskCompletion(userId: String, ongoingActivityId: String, taskId: String, isCompleted: Bool) async throws
    func getTodayTasks(userId: String) async throws -> [OngoingActivityTask]
    func listenToOngoingActivities(userId: String) -> AsyncStream<[OngoingActivity]>
}

@Observable
@MainActor
final class ActivityService: ActivityServiceProtocol {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func getActivities() async throws -> [Activity] {
        try await firestoreService.getDocuments(collection: "activities")
    }

    func getActivity(activityId: String) async throws -> Activity {
        try await firestoreService.getDocument(collection: "activities", id: activityId)
    }

    func getActivityTasks(activityId: String) async throws -> [ActivityTask] {
        try await firestoreService.getDocuments(collection: "activities/\(activityId)/activityTasks")
    }

    func getOngoingActivities(userId: String) async throws -> [OngoingActivity] {
        var activities: [OngoingActivity] = try await firestoreService.getDocuments(
            collection: "users/\(userId)/ongoing_activities"
        )

        // Enrich with activity details and scheduled tasks
        for i in activities.indices {
            if let activityId = activities[i].id {
                activities[i].activity = try? await getActivity(activityId: activities[i].activityId)
                activities[i].scheduledTasks = try? await getScheduledTasks(
                    userId: userId,
                    ongoingActivityId: activityId
                )
            }
        }

        return activities
    }

    func subscribeToActivity(userId: String, activityId: String, tasks: [ActivityTask]) async throws {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        let ongoingActivity = OngoingActivity(
            activityId: activityId,
            startDate: now,
            endDate: endDate,
            createdAt: now
        )

        let docId = try await firestoreService.addDocument(
            collection: "users/\(userId)/ongoing_activities",
            data: ongoingActivity
        )

        // Schedule tasks
        for task in tasks {
            let scheduledTask = OngoingActivityTask(
                taskId: task.id ?? "",
                scheduledDate: now,
                isCompleted: false
            )
            _ = try await firestoreService.addDocument(
                collection: "users/\(userId)/ongoing_activities/\(docId)/scheduledTasks",
                data: scheduledTask
            )
        }

        // Increment subscriber count
        try await firestoreService.firestore
            .collection("activities")
            .document(activityId)
            .updateData(["subscriberCount": FieldValue.increment(Int64(1))])
    }

    func unsubscribeFromActivity(userId: String, ongoingActivityId: String) async throws {
        // Get the activity to decrement subscriber count
        let ongoing: OngoingActivity = try await firestoreService.getDocument(
            collection: "users/\(userId)/ongoing_activities",
            id: ongoingActivityId
        )

        // Delete scheduled tasks
        let tasks: [OngoingActivityTask] = try await firestoreService.getDocuments(
            collection: "users/\(userId)/ongoing_activities/\(ongoingActivityId)/scheduledTasks"
        )
        for task in tasks {
            if let taskId = task.id {
                try await firestoreService.deleteDocument(
                    collection: "users/\(userId)/ongoing_activities/\(ongoingActivityId)/scheduledTasks",
                    id: taskId
                )
            }
        }

        // Delete ongoing activity
        try await firestoreService.deleteDocument(
            collection: "users/\(userId)/ongoing_activities",
            id: ongoingActivityId
        )

        // Decrement subscriber count
        try await firestoreService.firestore
            .collection("activities")
            .document(ongoing.activityId)
            .updateData(["subscriberCount": FieldValue.increment(Int64(-1))])
    }

    func toggleTaskCompletion(userId: String, ongoingActivityId: String, taskId: String, isCompleted: Bool) async throws {
        try await firestoreService.updateDocument(
            collection: "users/\(userId)/ongoing_activities/\(ongoingActivityId)/scheduledTasks",
            id: taskId,
            fields: ["isCompleted": isCompleted]
        )
    }

    func getTodayTasks(userId: String) async throws -> [OngoingActivityTask] {
        let ongoingActivities: [OngoingActivity] = try await firestoreService.getDocuments(
            collection: "users/\(userId)/ongoing_activities"
        )

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var todayTasks: [OngoingActivityTask] = []

        for activity in ongoingActivities {
            guard let activityDocId = activity.id else { continue }

            let tasks: [OngoingActivityTask] = try await firestoreService.getDocuments(
                collection: "users/\(userId)/ongoing_activities/\(activityDocId)/scheduledTasks",
                filters: [
                    .isGreaterThanOrEqualTo(field: "scheduledDate", value: Timestamp(date: startOfDay)),
                    .isLessThan(field: "scheduledDate", value: Timestamp(date: endOfDay))
                ]
            )

            // Enrich tasks with activity info
            let activityTasks = try? await getActivityTasks(activityId: activity.activityId)

            todayTasks += tasks.map { task in
                var enriched = task
                enriched.activityId = activityDocId
                enriched.task = activityTasks?.first(where: { $0.id == task.taskId })
                return enriched
            }
        }

        return todayTasks
    }

    func listenToOngoingActivities(userId: String) -> AsyncStream<[OngoingActivity]> {
        firestoreService.listenToCollection(
            collection: "users/\(userId)/ongoing_activities"
        )
    }

    private func getScheduledTasks(userId: String, ongoingActivityId: String) async throws -> [OngoingActivityTask] {
        try await firestoreService.getDocuments(
            collection: "users/\(userId)/ongoing_activities/\(ongoingActivityId)/scheduledTasks"
        )
    }
}
