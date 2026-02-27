import SwiftUI

struct VaultLayoutSettings: Codable, Equatable {
    var tabOrder: [VaultTab]
    var hiddenTabs: Set<VaultTab>
    var sectionOrder: [VaultSection]
    var hiddenSections: Set<VaultSection>

    static let defaultSettings = VaultLayoutSettings(
        tabOrder: VaultTab.allCases,
        hiddenTabs: [],
        sectionOrder: VaultSection.allCases,
        hiddenSections: []
    )
}

enum VaultSection: String, CaseIterable, Identifiable, Codable {
    case currentStreaks
    case statistics
    case calendar
    case streakAverages
    case riskClock
    case heatMapCalendar
    case triggerRadar
    case moodCorrelation

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .currentStreaks: return "vault.section.streaks"
        case .statistics: return "vault.section.statistics"
        case .calendar: return "vault.section.calendar"
        case .streakAverages: return "vault.section.streakAverages"
        case .riskClock: return "vault.section.riskClock"
        case .heatMapCalendar: return "vault.section.heatMap"
        case .triggerRadar: return "vault.section.triggerRadar"
        case .moodCorrelation: return "vault.section.moodCorrelation"
        }
    }

    var label: String {
        String(localized: String.LocalizationValue(labelKey))
    }

    var icon: String {
        switch self {
        case .currentStreaks: return "bolt.fill"
        case .statistics: return "chart.pie.fill"
        case .calendar: return "calendar"
        case .streakAverages: return "chart.line.uptrend.xyaxis"
        case .riskClock: return "clock.fill"
        case .heatMapCalendar: return "calendar.badge.clock"
        case .triggerRadar: return "antenna.radiowaves.left.and.right"
        case .moodCorrelation: return "heart.text.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .currentStreaks: return .indigo
        case .statistics: return .purple
        case .calendar: return .cyan
        case .streakAverages: return .green
        case .riskClock: return .cyan
        case .heatMapCalendar: return .red
        case .triggerRadar: return .orange
        case .moodCorrelation: return .pink
        }
    }

    var isPremium: Bool {
        switch self {
        case .currentStreaks, .statistics, .calendar:
            return false
        case .streakAverages, .riskClock, .heatMapCalendar, .triggerRadar, .moodCorrelation:
            return true
        }
    }

    var descriptionKey: String {
        switch self {
        case .currentStreaks: return "vault.section.streaks.desc"
        case .statistics: return "vault.section.statistics.desc"
        case .calendar: return "vault.section.calendar.desc"
        case .streakAverages: return "vault.section.streakAverages.desc"
        case .riskClock: return "vault.section.riskClock.desc"
        case .heatMapCalendar: return "vault.section.heatMap.desc"
        case .triggerRadar: return "vault.section.triggerRadar.desc"
        case .moodCorrelation: return "vault.section.moodCorrelation.desc"
        }
    }
}
