import Foundation

enum FollowUpType: String, Codable, CaseIterable {
    case relapse
    case pornOnly
    case mastOnly
    case slipUp
    case none

    var isRelapseRelated: Bool {
        switch self {
        case .relapse, .pornOnly, .mastOnly, .slipUp:
            return true
        case .none:
            return false
        }
    }
}
