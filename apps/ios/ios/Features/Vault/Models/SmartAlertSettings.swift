import Foundation

struct SmartAlertSettings: Codable {
    var isEnabled: Bool
    var alertTime: Date?
    var isEligible: Bool
    var eligibilityReason: String?

    static let empty = SmartAlertSettings(
        isEnabled: false,
        alertTime: nil,
        isEligible: false,
        eligibilityReason: nil
    )
}
