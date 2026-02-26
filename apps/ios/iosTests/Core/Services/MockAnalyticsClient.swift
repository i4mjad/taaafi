import Foundation
@testable import ios

final class MockAnalyticsClient: AnalyticsClient {
    var identifiedUsers: [String] = []
    var resetCount = 0
    var trackedEvents: [(name: String, properties: [String: Any]?)] = []
    var trackedScreens: [(routeName: String, action: String?)] = []

    func identifyUser(_ userId: String) {
        identifiedUsers.append(userId)
    }

    func resetUser() {
        resetCount += 1
    }

    func trackEvent(_ name: String, properties: [String: Any]?) {
        trackedEvents.append((name: name, properties: properties))
    }

    func trackScreenView(routeName: String, action: String?) {
        trackedScreens.append((routeName: routeName, action: action))
    }
}
