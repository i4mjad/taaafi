import SwiftUI

struct ToastMessage: Identifiable, Equatable {
    let id: UUID
    let variant: ToastVariant
    let message: String
    var actionLabel: String?
    var action: (() -> Void)?

    init(
        id: UUID = UUID(),
        variant: ToastVariant,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.variant = variant
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

enum ToastVariant: String, CaseIterable {
    case info
    case error
    case success
    case system
    case ban

    var icon: String {
        switch self {
        case .info: return AppIcon.info.systemName
        case .error: return AppIcon.alertCircle.systemName
        case .success: return AppIcon.check.systemName
        case .system: return AppIcon.info.systemName
        case .ban: return AppIcon.shieldOff.systemName
        }
    }

    var backgroundColor: Color {
        switch self {
        case .info: return AppColors.primary50
        case .error: return AppColors.error50
        case .success: return AppColors.success50
        case .system: return AppColors.grey50
        case .ban: return AppColors.error50
        }
    }

    var borderColor: Color {
        switch self {
        case .info: return AppColors.primary300
        case .error: return AppColors.error300
        case .success: return AppColors.success300
        case .system: return AppColors.grey300
        case .ban: return AppColors.error300
        }
    }

    var textColor: Color {
        switch self {
        case .info: return AppColors.primary900
        case .error: return AppColors.error900
        case .success: return AppColors.success900
        case .system: return AppColors.grey900
        case .ban: return AppColors.error900
        }
    }

    var iconColor: Color {
        switch self {
        case .info: return AppColors.primary600
        case .error: return AppColors.error600
        case .success: return AppColors.success600
        case .system: return AppColors.grey600
        case .ban: return AppColors.error600
        }
    }

    var autoDismissSeconds: TimeInterval {
        switch self {
        case .ban: return 5
        default: return 3
        }
    }
}
