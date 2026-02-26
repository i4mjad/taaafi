import Foundation

/// Protocol defining the analytics client interface
/// All analytics providers must conform to this protocol
/// Ported from: apps/mobile/lib/core/monitoring/analytics_client.dart
protocol AnalyticsClient {
    func identifyUser(_ userId: String)
    func resetUser()
    func trackEvent(_ name: String, properties: [String: Any]?)
    func trackScreenView(routeName: String, action: String?)
}

extension AnalyticsClient {
    func trackEvent(_ name: String) {
        trackEvent(name, properties: nil)
    }

    func trackScreenView(routeName: String) {
        trackScreenView(routeName: routeName, action: nil)
    }
}
