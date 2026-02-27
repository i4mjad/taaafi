import Foundation

@Observable
@MainActor
final class AddActivityViewModel {
    var activities: [Activity] = []
    var searchText = ""
    var isLoading = false
    var error: String?

    private let activityService: ActivityService

    init(activityService: ActivityService) {
        self.activityService = activityService
    }

    var filteredActivities: [Activity] {
        if searchText.isEmpty {
            return activities
        }
        return activities.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadActivities() async {
        isLoading = true
        do {
            activities = try await activityService.getActivities()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}
