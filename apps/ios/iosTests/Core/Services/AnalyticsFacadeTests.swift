import Testing
import Foundation
@testable import ios

@Suite("AnalyticsFacade")
@MainActor
struct AnalyticsFacadeTests {

    private let client1 = MockAnalyticsClient()
    private let client2 = MockAnalyticsClient()

    private var facade: AnalyticsFacade {
        AnalyticsFacade(clients: [client1, client2])
    }

    // MARK: - identifyUser

    @Test("identifyUser dispatches to all clients")
    func identifyUser() {
        facade.identifyUser("user-123")
        #expect(client1.identifiedUsers == ["user-123"])
        #expect(client2.identifiedUsers == ["user-123"])
    }

    // MARK: - resetUser

    @Test("resetUser dispatches to all clients")
    func resetUser() {
        facade.resetUser()
        #expect(client1.resetCount == 1)
        #expect(client2.resetCount == 1)
    }

    // MARK: - trackUserLogin / trackUserSignup

    @Test("trackUserLogin tracks 'login' event")
    func trackLogin() {
        facade.trackUserLogin()
        #expect(client1.trackedEvents.count == 1)
        #expect(client1.trackedEvents.first?.name == "login")
    }

    @Test("trackUserSignup tracks 'sign_up' event")
    func trackSignup() {
        facade.trackUserSignup()
        #expect(client1.trackedEvents.count == 1)
        #expect(client1.trackedEvents.first?.name == "sign_up")
    }

    // MARK: - trackScreenView

    @Test("trackScreenView dispatches with correct routeName and action")
    func trackScreenView() {
        facade.trackScreenView(routeName: "home", action: "tab_switch")
        #expect(client1.trackedScreens.count == 1)
        #expect(client1.trackedScreens.first?.routeName == "home")
        #expect(client1.trackedScreens.first?.action == "tab_switch")
    }

    @Test("trackScreenView with nil action")
    func trackScreenViewNilAction() {
        facade.trackScreenView(routeName: "settings")
        #expect(client1.trackedScreens.first?.action == nil)
    }

    // MARK: - Multiple clients

    @Test("All clients receive every event")
    func multipleClientsReceiveEvents() {
        facade.trackAppOpened()
        facade.trackUserLogin()
        #expect(client1.trackedEvents.count == 2)
        #expect(client2.trackedEvents.count == 2)
        #expect(client1.trackedEvents[0].name == "app_opened")
        #expect(client2.trackedEvents[1].name == "login")
    }

    // MARK: - trackEvent with properties

    @Test("trackEvent passes properties to clients")
    func trackEventWithProperties() {
        let props: [String: Any] = ["key": "value"]
        facade.trackEvent("custom_event", properties: props)
        #expect(client1.trackedEvents.first?.name == "custom_event")
        #expect(client1.trackedEvents.first?.properties?["key"] as? String == "value")
    }
}
