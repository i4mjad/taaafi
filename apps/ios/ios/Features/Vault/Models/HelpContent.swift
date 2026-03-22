import SwiftUI

// MARK: - Help Data Models

struct HelpSectionData: Identifiable {
    let id = UUID()
    let titleKey: String
    let items: [HelpItemData]
    let icon: String?
    let iconColor: Color?

    init(titleKey: String, items: [HelpItemData], icon: String? = nil, iconColor: Color? = nil) {
        self.titleKey = titleKey
        self.items = items
        self.icon = icon
        self.iconColor = iconColor
    }
}

struct HelpItemData: Identifiable {
    let id = UUID()
    let titleKey: String
    let descriptionKey: String
    let recoveryBenefitKey: String
    let icon: String?
    let iconColor: Color?

    init(titleKey: String, descriptionKey: String, recoveryBenefitKey: String = "", icon: String? = nil, iconColor: Color? = nil) {
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.recoveryBenefitKey = recoveryBenefitKey
        self.icon = icon
        self.iconColor = iconColor
    }
}

struct VaultHelpData {
    let titleKey: String
    let icon: String
    let iconColor: Color
    let howToReadSections: [HelpSectionData]
    let howToUseSections: [HelpSectionData]?
}

// MARK: - Help Content Factory

enum VaultHelpContent {

    static func content(for section: VaultSection) -> VaultHelpData {
        switch section {
        case .currentStreaks: return currentStreaksHelp
        case .statistics: return statisticsHelp
        case .calendar: return calendarHelp
        case .streakAverages: return streakAveragesHelp
        case .riskClock: return riskClockHelp
        case .heatMapCalendar: return heatMapHelp
        case .triggerRadar: return triggerRadarHelp
        case .moodCorrelation: return moodCorrelationHelp
        }
    }

    // MARK: - Current Streaks

    static let currentStreaksHelp = VaultHelpData(
        titleKey: "help.streaks.title",
        icon: "bolt.fill",
        iconColor: Color(red: 99/255, green: 102/255, blue: 241/255),
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.streaks.whatAreStreaks",
                items: [
                    HelpItemData(
                        titleKey: "help.streaks.definition",
                        descriptionKey: "help.streaks.definitionDesc",
                        recoveryBenefitKey: "help.streaks.definitionBenefit",
                        icon: "calendar",
                        iconColor: Color(red: 99/255, green: 102/255, blue: 241/255)
                    ),
                ]
            ),
            HelpSectionData(
                titleKey: "help.streaks.types",
                items: [
                    HelpItemData(
                        titleKey: "help.streaks.relapseFree",
                        descriptionKey: "help.streaks.relapseFreeDesc",
                        recoveryBenefitKey: "help.streaks.relapseFreeBenefit",
                        icon: "heart.fill",
                        iconColor: .green
                    ),
                    HelpItemData(
                        titleKey: "help.streaks.pornFree",
                        descriptionKey: "help.streaks.pornFreeDesc",
                        recoveryBenefitKey: "help.streaks.pornFreeBenefit",
                        icon: "eye.fill",
                        iconColor: .purple
                    ),
                    HelpItemData(
                        titleKey: "help.streaks.cleanDays",
                        descriptionKey: "help.streaks.cleanDaysDesc",
                        recoveryBenefitKey: "help.streaks.cleanDaysBenefit",
                        icon: "person.fill",
                        iconColor: .cyan
                    ),
                    HelpItemData(
                        titleKey: "help.streaks.slipUpFree",
                        descriptionKey: "help.streaks.slipUpFreeDesc",
                        recoveryBenefitKey: "help.streaks.slipUpFreeBenefit",
                        icon: "shield.fill",
                        iconColor: .orange
                    ),
                ]
            ),
        ],
        howToUseSections: [
            HelpSectionData(
                titleKey: "help.streaks.managing",
                items: [
                    HelpItemData(
                        titleKey: "help.streaks.viewingDetailed",
                        descriptionKey: "help.streaks.viewingDetailedDesc",
                        recoveryBenefitKey: "help.streaks.viewingDetailedBenefit",
                        icon: "eye.fill",
                        iconColor: Color(red: 99/255, green: 102/255, blue: 241/255)
                    ),
                    HelpItemData(
                        titleKey: "help.streaks.switchingModes",
                        descriptionKey: "help.streaks.switchingModesDesc",
                        recoveryBenefitKey: "help.streaks.switchingModesBenefit",
                        icon: "switch.2",
                        iconColor: .purple
                    ),
                ]
            ),
            HelpSectionData(
                titleKey: "help.streaks.actions",
                items: [
                    HelpItemData(
                        titleKey: "help.streaks.recordingFollowUps",
                        descriptionKey: "help.streaks.recordingFollowUpsDesc",
                        recoveryBenefitKey: "help.streaks.recordingFollowUpsBenefit",
                        icon: "plus",
                        iconColor: .green
                    ),
                    HelpItemData(
                        titleKey: "help.streaks.resetting",
                        descriptionKey: "help.streaks.resettingDesc",
                        recoveryBenefitKey: "help.streaks.resettingBenefit",
                        icon: "arrow.counterclockwise",
                        iconColor: .orange
                    ),
                ]
            ),
        ]
    )

    // MARK: - Statistics

    static let statisticsHelp = VaultHelpData(
        titleKey: "help.statistics.title",
        icon: "chart.pie.fill",
        iconColor: Color(red: 139/255, green: 92/255, blue: 246/255),
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.statistics.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.statistics.purpose",
                        descriptionKey: "help.statistics.purposeDesc",
                        recoveryBenefitKey: "help.statistics.purposeBenefit",
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .purple
                    ),
                ]
            ),
            HelpSectionData(
                titleKey: "help.statistics.metrics",
                items: [
                    HelpItemData(
                        titleKey: "help.statistics.totalCleanDays",
                        descriptionKey: "help.statistics.totalCleanDaysDesc",
                        recoveryBenefitKey: "help.statistics.totalCleanDaysBenefit",
                        icon: "heart.fill",
                        iconColor: .green
                    ),
                    HelpItemData(
                        titleKey: "help.statistics.longestStreak",
                        descriptionKey: "help.statistics.longestStreakDesc",
                        recoveryBenefitKey: "help.statistics.longestStreakBenefit",
                        icon: "trophy.fill",
                        iconColor: .yellow
                    ),
                    HelpItemData(
                        titleKey: "help.statistics.recentRelapses",
                        descriptionKey: "help.statistics.recentRelapsesDesc",
                        recoveryBenefitKey: "help.statistics.recentRelapsesBenefit",
                        icon: "calendar",
                        iconColor: .red
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )

    // MARK: - Calendar

    static let calendarHelp = VaultHelpData(
        titleKey: "help.calendar.title",
        icon: "calendar",
        iconColor: .cyan,
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.calendar.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.calendar.purpose",
                        descriptionKey: "help.calendar.purposeDesc",
                        recoveryBenefitKey: "help.calendar.purposeBenefit",
                        icon: "calendar",
                        iconColor: .cyan
                    ),
                ]
            ),
            HelpSectionData(
                titleKey: "help.calendar.colorCoding",
                items: [
                    HelpItemData(
                        titleKey: "help.calendar.cleanDays",
                        descriptionKey: "help.calendar.cleanDaysDesc",
                        recoveryBenefitKey: "help.calendar.cleanDaysBenefit",
                        icon: "circle.fill",
                        iconColor: .green
                    ),
                    HelpItemData(
                        titleKey: "help.calendar.relapseDays",
                        descriptionKey: "help.calendar.relapseDaysDesc",
                        recoveryBenefitKey: "help.calendar.relapseDaysBenefit",
                        icon: "circle.fill",
                        iconColor: .red
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )

    // MARK: - Premium Analytics

    static let streakAveragesHelp = VaultHelpData(
        titleKey: "help.streakAverages.title",
        icon: "chart.line.uptrend.xyaxis",
        iconColor: .green,
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.streakAverages.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.streakAverages.purpose",
                        descriptionKey: "help.streakAverages.purposeDesc",
                        recoveryBenefitKey: "help.streakAverages.purposeBenefit",
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .green
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )

    static let riskClockHelp = VaultHelpData(
        titleKey: "help.riskClock.title",
        icon: "clock.fill",
        iconColor: .cyan,
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.riskClock.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.riskClock.purpose",
                        descriptionKey: "help.riskClock.purposeDesc",
                        recoveryBenefitKey: "help.riskClock.purposeBenefit",
                        icon: "clock.fill",
                        iconColor: .cyan
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )

    static let heatMapHelp = VaultHelpData(
        titleKey: "help.heatMap.title",
        icon: "calendar",
        iconColor: .red,
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.heatMap.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.heatMap.purpose",
                        descriptionKey: "help.heatMap.purposeDesc",
                        recoveryBenefitKey: "help.heatMap.purposeBenefit",
                        icon: "calendar",
                        iconColor: .red
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )

    static let triggerRadarHelp = VaultHelpData(
        titleKey: "help.triggerRadar.title",
        icon: "scope",
        iconColor: .orange,
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.triggerRadar.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.triggerRadar.purpose",
                        descriptionKey: "help.triggerRadar.purposeDesc",
                        recoveryBenefitKey: "help.triggerRadar.purposeBenefit",
                        icon: "scope",
                        iconColor: .orange
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )

    static let moodCorrelationHelp = VaultHelpData(
        titleKey: "help.moodCorrelation.title",
        icon: "heart.text.clipboard",
        iconColor: .pink,
        howToReadSections: [
            HelpSectionData(
                titleKey: "help.moodCorrelation.overview",
                items: [
                    HelpItemData(
                        titleKey: "help.moodCorrelation.purpose",
                        descriptionKey: "help.moodCorrelation.purposeDesc",
                        recoveryBenefitKey: "help.moodCorrelation.purposeBenefit",
                        icon: "heart.text.clipboard",
                        iconColor: .pink
                    ),
                ]
            ),
        ],
        howToUseSections: nil
    )
}
