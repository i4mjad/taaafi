import Foundation

protocol SubscriptionServiceProtocol: Observable {
    var isSubscribed: Bool { get }
}
