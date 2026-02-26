import SwiftUI

enum AccountStatus: String, CaseIterable {
    case loading
    case ok
    case needCompleteRegistration
    case needConfirmDetails
    case needEmailVerification
    case pendingDeletion
    case error
}

struct BannerConfig {
    let icon: String
    let iconColor: Color
    let textColor: Color
    let buttonColor: Color
    let titleKey: String
    let subtitleKey: String
    let actionLabel: String
}

func bannerConfig(for status: AccountStatus) -> BannerConfig? {
    switch status {
    case .loading, .ok:
        return nil

    case .needCompleteRegistration:
        return BannerConfig(
            icon: AppIcon.alertTriangle.systemName,
            iconColor: AppColors.warning600,
            textColor: AppColors.warning800,
            buttonColor: AppColors.warning600,
            titleKey: Strings.Account.completeRegistration,
            subtitleKey: Strings.Account.completeRegistrationSubtitle,
            actionLabel: Strings.Account.completeRegistrationButton
        )

    case .needConfirmDetails:
        return BannerConfig(
            icon: AppIcon.alertCircle.systemName,
            iconColor: AppColors.error600,
            textColor: AppColors.error800,
            buttonColor: AppColors.error600,
            titleKey: Strings.Account.confirmDetails,
            subtitleKey: Strings.Account.confirmDetailsSubtitle,
            actionLabel: Strings.Account.confirmDetailsButton
        )

    case .needEmailVerification:
        return BannerConfig(
            icon: AppIcon.mail.systemName,
            iconColor: AppColors.primary600,
            textColor: AppColors.primary800,
            buttonColor: AppColors.primary600,
            titleKey: Strings.Account.emailVerification,
            subtitleKey: Strings.Account.emailVerificationSubtitle,
            actionLabel: Strings.Account.emailVerificationButton
        )

    case .pendingDeletion:
        return BannerConfig(
            icon: AppIcon.userX.systemName,
            iconColor: AppColors.error600,
            textColor: AppColors.error800,
            buttonColor: AppColors.error600,
            titleKey: Strings.Account.pendingDeletion,
            subtitleKey: Strings.Account.pendingDeletionSubtitle,
            actionLabel: Strings.Account.cancelDeletion
        )

    case .error:
        return BannerConfig(
            icon: AppIcon.alertCircle.systemName,
            iconColor: AppColors.error600,
            textColor: AppColors.error800,
            buttonColor: AppColors.error600,
            titleKey: Strings.Account.error,
            subtitleKey: Strings.Account.errorSubtitle,
            actionLabel: Strings.Common.retry
        )
    }
}
