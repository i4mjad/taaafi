import SwiftUI

enum VaultTab: String, CaseIterable, Identifiable, Codable {
    case vault
    case activities
    case library
    case diaries
    case messagingGroups
    case settings

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .vault: return "vault.tab.vault"
        case .activities: return "vault.tab.activities"
        case .library: return "vault.tab.library"
        case .diaries: return "vault.tab.diaries"
        case .messagingGroups: return "vault.tab.messaging"
        case .settings: return "vault.tab.settings"
        }
    }

    var label: String {
        String(localized: String.LocalizationValue(labelKey))
    }

    var icon: String {
        switch self {
        case .vault: return "lock.fill"
        case .activities: return "checklist"
        case .library: return "book.fill"
        case .diaries: return "pencil.line"
        case .messagingGroups: return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .vault: return AppColors.primary
        case .activities: return AppColors.primary
        case .library: return AppColors.secondary
        case .diaries: return AppColors.tint500
        case .messagingGroups: return AppColors.warning
        case .settings: return AppColors.grey700
        }
    }
}
