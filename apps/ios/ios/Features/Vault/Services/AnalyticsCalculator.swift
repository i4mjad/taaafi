import Foundation

struct AnalyticsCalculator {

    // MARK: - Streak Averages (7/30/90 day clean percentages)

    struct StreakAverages: Equatable {
        var sevenDay: Double    // 0.0 - 1.0
        var thirtyDay: Double
        var ninetyDay: Double
    }

    static func calculateStreakAverages(followUps: [FollowUpModel], userFirstDate: Date) -> StreakAverages {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let relapseSet = Set(followUps.filter { $0.type == .relapse }.map { calendar.startOfDay(for: $0.time) })

        func cleanPercentage(days: Int) -> Double {
            let start = max(
                calendar.date(byAdding: .day, value: -days, to: today)!,
                calendar.startOfDay(for: userFirstDate)
            )
            let totalDays = max(1, calendar.dateComponents([.day], from: start, to: today).day ?? 1)
            let relapseDays = relapseSet.filter { $0 >= start && $0 <= today }.count
            return Double(totalDays - relapseDays) / Double(totalDays)
        }

        return StreakAverages(
            sevenDay: cleanPercentage(days: 7),
            thirtyDay: cleanPercentage(days: 30),
            ninetyDay: cleanPercentage(days: 90)
        )
    }

    // MARK: - Risk Clock (24-hour histogram)

    struct HourlyRisk: Identifiable, Equatable {
        let id: Int  // hour 0-23
        let count: Int
    }

    static func calculateRiskClock(followUps: [FollowUpModel]) -> [HourlyRisk] {
        var hourCounts = [Int](repeating: 0, count: 24)

        let relapseFollowUps = followUps.filter { $0.type.isRelapseRelated }
        let calendar = Calendar.current

        for followUp in relapseFollowUps {
            let hour = calendar.component(.hour, from: followUp.time)
            hourCounts[hour] += 1
        }

        return (0..<24).map { HourlyRisk(id: $0, count: hourCounts[$0]) }
    }

    // MARK: - Heat Map (daily density for a month)

    struct DayHeat: Identifiable, Equatable {
        let id: Date
        let count: Int
        let intensity: Double  // 0.0 - 1.0
    }

    static func calculateHeatMap(followUps: [FollowUpModel], month: Date) -> [DayHeat] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        let year = calendar.component(.year, from: month)
        let monthNum = calendar.component(.month, from: month)

        var dayCounts: [Int: Int] = [:]

        for followUp in followUps.filter({ $0.type.isRelapseRelated }) {
            let day = calendar.component(.day, from: followUp.time)
            let m = calendar.component(.month, from: followUp.time)
            let y = calendar.component(.year, from: followUp.time)
            if m == monthNum && y == year {
                dayCounts[day, default: 0] += 1
            }
        }

        let maxCount = max(1, dayCounts.values.max() ?? 1)

        return range.compactMap { day -> DayHeat? in
            guard let date = calendar.date(from: DateComponents(year: year, month: monthNum, day: day)) else { return nil }
            let count = dayCounts[day] ?? 0
            return DayHeat(id: date, count: count, intensity: Double(count) / Double(maxCount))
        }
    }

    // MARK: - Trigger Radar (top 6 triggers)

    struct TriggerCount: Identifiable, Equatable {
        var id: String { trigger }
        let trigger: String
        let count: Int
    }

    static func calculateTriggerRadar(followUps: [FollowUpModel]) -> [TriggerCount] {
        var triggerCounts: [String: Int] = [:]

        for followUp in followUps where followUp.type.isRelapseRelated {
            for trigger in followUp.triggers {
                triggerCounts[trigger, default: 0] += 1
            }
        }

        return triggerCounts
            .map { TriggerCount(trigger: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    // MARK: - Mood Correlation

    struct MoodCorrelation: Identifiable, Equatable {
        var id: String { emotionName }
        let emotionName: String
        let emoji: String
        let relapseCount: Int
        let cleanCount: Int
    }

    static func calculateMoodCorrelation(
        emotions: [EmotionModel],
        followUps: [FollowUpModel]
    ) -> [MoodCorrelation] {
        let calendar = Calendar.current

        let relapseDates = Set(followUps.filter { $0.type.isRelapseRelated }.map { calendar.startOfDay(for: $0.time) })

        var emotionOnRelapse: [String: (emoji: String, relapseCount: Int, cleanCount: Int)] = [:]

        for emotion in emotions {
            let day = calendar.startOfDay(for: emotion.date)
            let isRelapseDay = relapseDates.contains(day)

            var existing = emotionOnRelapse[emotion.emotionName] ?? (emoji: emotion.emotionEmoji, relapseCount: 0, cleanCount: 0)
            if isRelapseDay {
                existing.relapseCount += 1
            } else {
                existing.cleanCount += 1
            }
            emotionOnRelapse[emotion.emotionName] = existing
        }

        return emotionOnRelapse
            .map { MoodCorrelation(emotionName: $0.key, emoji: $0.value.emoji, relapseCount: $0.value.relapseCount, cleanCount: $0.value.cleanCount) }
            .sorted { ($0.relapseCount + $0.cleanCount) > ($1.relapseCount + $1.cleanCount) }
            .prefix(8)
            .map { $0 }
    }
}
