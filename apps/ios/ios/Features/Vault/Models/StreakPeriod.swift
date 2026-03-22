import Foundation

struct StreakPeriod: Identifiable, Equatable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let durationDays: Int
    let followUpType: FollowUpType
}
