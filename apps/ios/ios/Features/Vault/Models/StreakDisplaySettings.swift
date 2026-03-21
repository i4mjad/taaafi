import Foundation

enum StreakDisplayMode: String, Codable {
    case days
    case detailed
}

struct StreakVisibility: Codable, Equatable {
    var relapse: Bool
    var pornOnly: Bool
    var mastOnly: Bool
    var slipUp: Bool

    static let defaultVisibility = StreakVisibility(
        relapse: true,
        pornOnly: true,
        mastOnly: true,
        slipUp: true
    )
}

struct StreakDisplaySettings: Codable, Equatable {
    var displayMode: StreakDisplayMode
    var visibility: StreakVisibility

    static let defaultSettings = StreakDisplaySettings(
        displayMode: .days,
        visibility: .defaultVisibility
    )
}
