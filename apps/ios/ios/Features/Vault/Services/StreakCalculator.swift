import Foundation

struct StreakCalculator {

    static func calculateStreaks(followUps: [FollowUpModel], userFirstDate: Date) -> StreakStatistics {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: userFirstDate)

        // Group follow-ups by date
        var followUpsByDate: [Date: [FollowUpType]] = [:]
        for followUp in followUps {
            let day = calendar.startOfDay(for: followUp.time)
            followUpsByDate[day, default: []].append(followUp.type)
        }

        // Calculate streak for each type
        let relapseStreak = calculateStreak(for: .relapse, from: today, startDate: startDate, followUpsByDate: followUpsByDate, calendar: calendar)
        let pornOnlyStreak = calculateStreak(for: .pornOnly, from: today, startDate: startDate, followUpsByDate: followUpsByDate, calendar: calendar)
        let mastOnlyStreak = calculateStreak(for: .mastOnly, from: today, startDate: startDate, followUpsByDate: followUpsByDate, calendar: calendar)
        let slipUpStreak = calculateStreak(for: .slipUp, from: today, startDate: startDate, followUpsByDate: followUpsByDate, calendar: calendar)

        return StreakStatistics(
            relapseStreak: relapseStreak,
            pornOnlyStreak: pornOnlyStreak,
            mastOnlyStreak: mastOnlyStreak,
            slipUpStreak: slipUpStreak,
            userFirstDate: userFirstDate
        )
    }

    static func calculateUserStatistics(followUps: [FollowUpModel], userFirstDate: Date) -> UserStatistics {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: userFirstDate)

        var followUpsByDate: [Date: [FollowUpType]] = [:]
        for followUp in followUps {
            let day = calendar.startOfDay(for: followUp.time)
            followUpsByDate[day, default: []].append(followUp.type)
        }

        let currentStreak = calculateStreak(for: .relapse, from: today, startDate: startDate, followUpsByDate: followUpsByDate, calendar: calendar)

        // Count relapses in last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        let recentRelapses = followUps.filter { followUp in
            followUp.type == .relapse && followUp.time >= thirtyDaysAgo
        }.count

        // Find longest streak
        let longestStreak = calculateLongestStreak(for: .relapse, startDate: startDate, endDate: today, followUpsByDate: followUpsByDate, calendar: calendar)

        return UserStatistics(
            daysWithoutRelapse: currentStreak,
            relapsesInLast30Days: recentRelapses,
            longestRelapseStreak: longestStreak
        )
    }

    // MARK: - Periods

    static func calculatePeriods(
        for type: FollowUpType,
        followUps: [FollowUpModel],
        userFirstDate: Date
    ) -> [StreakPeriod] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: userFirstDate)

        // Group follow-ups by date
        var followUpsByDate: [Date: [FollowUpType]] = [:]
        for followUp in followUps {
            let day = calendar.startOfDay(for: followUp.time)
            followUpsByDate[day, default: []].append(followUp.type)
        }

        var periods: [StreakPeriod] = []
        var periodStart = startDate
        var currentDate = startDate

        while currentDate <= today {
            let types = followUpsByDate[currentDate] ?? []
            if types.contains(type) {
                // End of a streak period
                let days = calendar.dateComponents([.day], from: periodStart, to: currentDate).day ?? 0
                if days > 0 {
                    periods.append(StreakPeriod(
                        startDate: periodStart,
                        endDate: calendar.date(byAdding: .day, value: -1, to: currentDate)!,
                        durationDays: days,
                        followUpType: type
                    ))
                }
                periodStart = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Add the current ongoing period
        let ongoingDays = calendar.dateComponents([.day], from: periodStart, to: today).day ?? 0
        if ongoingDays >= 0 {
            periods.append(StreakPeriod(
                startDate: periodStart,
                endDate: today,
                durationDays: ongoingDays + 1, // Include today
                followUpType: type
            ))
        }

        return periods
    }

    // MARK: - Private

    private static func calculateStreak(
        for type: FollowUpType,
        from endDate: Date,
        startDate: Date,
        followUpsByDate: [Date: [FollowUpType]],
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var currentDate = endDate

        while currentDate >= startDate {
            let types = followUpsByDate[currentDate] ?? []
            if types.contains(type) {
                break
            }
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return streak
    }

    private static func calculateLongestStreak(
        for type: FollowUpType,
        startDate: Date,
        endDate: Date,
        followUpsByDate: [Date: [FollowUpType]],
        calendar: Calendar
    ) -> Int {
        var longestStreak = 0
        var currentStreak = 0
        var currentDate = startDate

        while currentDate <= endDate {
            let types = followUpsByDate[currentDate] ?? []
            if types.contains(type) {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 0
            } else {
                currentStreak += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return max(longestStreak, currentStreak)
    }
}
