import Foundation

/// Facade that dispatches analytics events to all registered clients
/// Currently Firebase Analytics only; protocol-based design allows adding more clients later
@Observable
@MainActor
final class AnalyticsFacade {

    private let clients: [AnalyticsClient]

    init(clients: [AnalyticsClient]) {
        self.clients = clients
    }

    convenience init() {
        self.init(clients: [
            FirebaseAnalyticsClient(),
        ])
    }

    // MARK: - User Identification

    func identifyUser(_ userId: String) {
        dispatch { $0.identifyUser(userId) }
    }

    func resetUser() {
        dispatch { $0.resetUser() }
    }

    // MARK: - Screen Tracking

    func trackScreenView(routeName: String, action: String? = nil) {
        dispatch { $0.trackScreenView(routeName: routeName, action: action) }
    }

    // MARK: - App Lifecycle

    func trackAppOpened() { track("app_opened") }
    func trackAppClosed() { track("app_closed") }

    // MARK: - Auth Events

    func trackUserLogin() { track("login") }
    func trackUserSignup() { track("sign_up") }
    func trackUserLogout() { track("logout") }
    func trackUserUpdateProfile() { track("user_update_profile") }
    func trackUserDeleteAccount() { track("user_delete_account") }

    // MARK: - Onboarding

    func trackOnboarding() { track("onboarding") }
    func trackOnboardingStart() { track("onboarding_start") }
    func trackOnboardingFinish() { track("onboarding_finish") }

    // MARK: - Follow-Up

    func trackNewFollowUpAdded() { track("new_follow_up_added") }
    func trackFollowUpUpdated() { track("follow_up_updated") }
    func trackFollowUpRemoved() { track("follow_up_removed") }

    // MARK: - Activity

    func trackActivityFetchStarted() { track("activity_fetch_started") }
    func trackActivityFetchFinished() { track("activity_fetch_finished") }
    func trackActivityFetchFailed() { track("activity_fetch_failed") }

    func trackActivitySubscriptionStarted() { track("activity_subscription_started") }
    func trackActivitySubscriptionFinished() { track("activity_subscription_finished") }
    func trackActivitySubscriptionFailed() { track("activity_subscription_failed") }

    func trackActivityUpdateStarted() { track("activity_update_started") }
    func trackActivityUpdateFinished() { track("activity_update_finished") }
    func trackActivityUpdateFailed() { track("activity_update_failed") }

    func trackActivityDeleteStarted() { track("activity_delete_started") }
    func trackActivityDeleteFinished() { track("activity_delete_finished") }
    func trackActivityDeleteFailed() { track("activity_delete_failed") }

    // MARK: - Progress

    func trackProgressCalculationStarted() { track("progress_calculation_started") }
    func trackProgressCalculationFinished() { track("progress_calculation_finished") }
    func trackProgressCalculationFailed() { track("progress_calculation_failed") }

    // MARK: - Task Completion

    func trackTaskCompletionStarted() { track("task_completion_started") }
    func trackTaskCompletionFinished() { track("task_completion_finished") }
    func trackTaskCompletionFailed() { track("task_completion_failed") }

    // MARK: - Data Reset

    func trackUserResetDataStarted() { track("user_reset_data_started") }
    func trackUserResetDataFinished() { track("user_reset_data_finished") }

    // MARK: - Generic

    func trackEvent(_ name: String, properties: [String: Any]? = nil) {
        dispatch { $0.trackEvent(name, properties: properties) }
    }

    // MARK: - Private

    private func track(_ name: String) {
        dispatch { $0.trackEvent(name, properties: nil) }
    }

    private func dispatch(_ work: (AnalyticsClient) -> Void) {
        for client in clients {
            work(client)
        }
    }
}
