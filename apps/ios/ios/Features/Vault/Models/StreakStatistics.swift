import Foundation

struct StreakStatistics: Equatable {
    var relapseStreak: Int
    var pornOnlyStreak: Int
    var mastOnlyStreak: Int
    var slipUpStreak: Int
    var userFirstDate: Date

    static let empty = StreakStatistics(
        relapseStreak: 0,
        pornOnlyStreak: 0,
        mastOnlyStreak: 0,
        slipUpStreak: 0,
        userFirstDate: Date()
    )
}

struct UserStatistics: Equatable {
    var daysWithoutRelapse: Int
    var relapsesInLast30Days: Int
    var longestRelapseStreak: Int

    static let empty = UserStatistics(
        daysWithoutRelapse: 0,
        relapsesInLast30Days: 0,
        longestRelapseStreak: 0
    )
}
