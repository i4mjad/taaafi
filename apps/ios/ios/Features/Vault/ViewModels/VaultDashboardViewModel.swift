import SwiftUI
import FirebaseAuth

@Observable
@MainActor
final class VaultDashboardViewModel {
    var streaks = StreakStatistics.empty
    var statistics = UserStatistics.empty
    var followUps: [FollowUpModel] = []
    var calendarFollowUps: [FollowUpModel] = []
    var calendarMonth = Date()
    var isLoading = false
    var error: String?

    // Premium analytics
    var streakAverages = AnalyticsCalculator.StreakAverages(sevenDay: 0, thirtyDay: 0, ninetyDay: 0)
    var riskClockData: [AnalyticsCalculator.HourlyRisk] = []
    var heatMapData: [AnalyticsCalculator.DayHeat] = []
    var triggerRadarData: [AnalyticsCalculator.TriggerCount] = []
    var moodCorrelationData: [AnalyticsCalculator.MoodCorrelation] = []

    private let followUpService: FollowUpService
    private let emotionService: EmotionService
    private var userFirstDate: Date

    init(followUpService: FollowUpService, emotionService: EmotionService, userFirstDate: Date) {
        self.followUpService = followUpService
        self.emotionService = emotionService
        self.userFirstDate = userFirstDate
    }

    func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        error = nil

        do {
            // Fetch all follow-ups from user's first date
            let allFollowUps = try await followUpService.getFollowUps(
                userId: userId,
                startDate: userFirstDate,
                endDate: Date()
            )
            self.followUps = allFollowUps

            // Calculate streaks and statistics
            streaks = StreakCalculator.calculateStreaks(followUps: allFollowUps, userFirstDate: userFirstDate)
            statistics = StreakCalculator.calculateUserStatistics(followUps: allFollowUps, userFirstDate: userFirstDate)

            // Load calendar data for current month
            await loadCalendarMonth(calendarMonth)

            // Calculate analytics
            streakAverages = AnalyticsCalculator.calculateStreakAverages(followUps: allFollowUps, userFirstDate: userFirstDate)
            riskClockData = AnalyticsCalculator.calculateRiskClock(followUps: allFollowUps)
            heatMapData = AnalyticsCalculator.calculateHeatMap(followUps: allFollowUps, month: calendarMonth)
            triggerRadarData = AnalyticsCalculator.calculateTriggerRadar(followUps: allFollowUps)

            // Mood correlation needs emotions too
            let emotions = try await emotionService.getEmotions(
                userId: userId,
                startDate: userFirstDate,
                endDate: Date()
            )
            moodCorrelationData = AnalyticsCalculator.calculateMoodCorrelation(emotions: emotions, followUps: allFollowUps)

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func loadCalendarMonth(_ month: Date) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        do {
            calendarFollowUps = try await followUpService.getFollowUps(
                userId: userId,
                startDate: startOfMonth,
                endDate: endOfMonth
            )
            heatMapData = AnalyticsCalculator.calculateHeatMap(followUps: followUps, month: month)
        } catch {
            print("[VaultDashboard] Calendar load error: \(error.localizedDescription)")
        }
    }
}
