import Foundation
import FirebaseAnalytics

/// Wraps Firebase Analytics for event tracking and screen views
/// Ported from: apps/mobile/lib/core/monitoring/google_analytics_client.dart
final class FirebaseAnalyticsClient: AnalyticsClient {

    func identifyUser(_ userId: String) {
        Analytics.setUserID(userId)
    }

    func resetUser() {
        Analytics.setUserID(nil)
    }

    func trackEvent(_ name: String, properties: [String: Any]?) {
        Analytics.logEvent(name, parameters: properties)
    }

    func trackScreenView(routeName: String, action: String?) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: routeName,
            AnalyticsParameterScreenClass: action ?? routeName,
        ])
    }
}
