import Foundation
import Mixpanel

/// Wraps Mixpanel SDK for event tracking
/// Ported from: apps/mobile/lib/core/monitoring/mixpanel_analytics_client.dart
final class MixpanelAnalyticsClient: AnalyticsClient {

    static let token = "ac8731373dcf0a35a44d43ab1e3ea5f1"

    private let mixpanel: MixpanelInstance

    init() {
        mixpanel = Mixpanel.initialize(token: Self.token, trackAutomaticEvents: true)
    }

    func identifyUser(_ userId: String) {
        mixpanel.identify(distinctId: userId)
    }

    func resetUser() {
        mixpanel.reset()
    }

    func trackEvent(_ name: String, properties: [String: Any]?) {
        if let properties {
            let mpProperties = properties.compactMapValues { value -> MixpanelType? in
                if let str = value as? String { return str }
                if let num = value as? NSNumber { return num }
                if let bool = value as? Bool { return bool }
                return "\(value)"
            }
            mixpanel.track(event: name, properties: mpProperties)
        } else {
            mixpanel.track(event: name)
        }
    }

    func trackScreenView(routeName: String, action: String?) {
        var props: Properties = ["name": routeName]
        if let action {
            props["action"] = action
        }
        mixpanel.track(event: "Screen View", properties: props)
    }
}
