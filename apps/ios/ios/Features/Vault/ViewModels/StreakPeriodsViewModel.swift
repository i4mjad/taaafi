import Foundation
import FirebaseAuth

@Observable
@MainActor
final class StreakPeriodsViewModel {
    var periods: [StreakPeriod] = []
    var isLoading = true
    var error: String?
    var displayMode: StreakPeriodsDisplayMode = .summary

    let followUpType: FollowUpType

    private let followUpService: FollowUpService
    private let userFirstDate: Date

    init(followUpType: FollowUpType, followUpService: FollowUpService, userFirstDate: Date) {
        self.followUpType = followUpType
        self.followUpService = followUpService
        self.userFirstDate = userFirstDate
    }

    func loadPeriods() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        error = nil

        do {
            let followUps = try await followUpService.getFollowUps(
                userId: userId,
                startDate: userFirstDate,
                endDate: Date()
            )
            periods = StreakCalculator.calculatePeriods(
                for: followUpType,
                followUps: followUps,
                userFirstDate: userFirstDate
            )
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    // Chart data
    var chartPoints: [(index: Int, duration: Int)] {
        periods.enumerated().map { (index, period) in
            (index: index, duration: period.durationDays)
        }
    }

    var maxDuration: Int {
        max(periods.map(\.durationDays).max() ?? 0, 10)
    }

    var averageDuration: Double {
        guard !periods.isEmpty else { return 0 }
        return Double(periods.map(\.durationDays).reduce(0, +)) / Double(periods.count)
    }

    var totalPeriods: Int { periods.count }
}

enum StreakPeriodsDisplayMode: String {
    case summary
    case detailed
}
