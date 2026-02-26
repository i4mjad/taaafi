import Foundation

enum Strings {

    enum Tab {
        static let home = String(localized: "tab.home")
        static let vault = String(localized: "tab.vault")
        static let `guard` = String(localized: "tab.guard")
        static let community = String(localized: "tab.community")
        static let account = String(localized: "tab.account")
    }

    enum Guard {
        static let title = String(localized: "guard.title")
        static let today = String(localized: "guard.today")
        static let yesterday = String(localized: "guard.yesterday")
        static let screenTimePermission = String(localized: "guard.screenTimePermission")
        static let screenTimeDescription = String(localized: "guard.screenTimeDescription")
        static let enableAccess = String(localized: "guard.enableAccess")
        static let selectDate = String(localized: "guard.selectDate")
        static let done = String(localized: "guard.done")
        static let settings = String(localized: "guard.settings")
        static let safe = String(localized: "guard.safe")
        static let neutral = String(localized: "guard.neutral")
        static let threat = String(localized: "guard.threat")
        static let categoryClassifications = String(localized: "guard.categoryClassifications")
        static let categoryFooter = String(localized: "guard.categoryFooter")
    }

    enum Common {
        static let loading = String(localized: "common.loading")
        static let accessRestricted = String(localized: "common.accessRestricted")
        static let accessRestrictedMessage = String(localized: "common.accessRestrictedMessage")
        static let done = String(localized: "common.done")
        static let cancel = String(localized: "common.cancel")
        static let confirm = String(localized: "common.confirm")
        static let signOut = String(localized: "common.signOut")
        static let retry = String(localized: "common.retry")
    }

    enum Account {
        static let completeRegistration = String(localized: "account.completeRegistration")
        static let completeRegistrationSubtitle = String(localized: "account.completeRegistrationSubtitle")
        static let completeRegistrationButton = String(localized: "account.completeRegistrationButton")
        static let confirmDetails = String(localized: "account.confirmDetails")
        static let confirmDetailsSubtitle = String(localized: "account.confirmDetailsSubtitle")
        static let confirmDetailsButton = String(localized: "account.confirmDetailsButton")
        static let emailVerification = String(localized: "account.emailVerification")
        static let emailVerificationSubtitle = String(localized: "account.emailVerificationSubtitle")
        static let emailVerificationButton = String(localized: "account.emailVerificationButton")
        static let pendingDeletion = String(localized: "account.pendingDeletion")
        static let pendingDeletionSubtitle = String(localized: "account.pendingDeletionSubtitle")
        static let deletionScheduled = String(localized: "account.deletionScheduled")
        static let cancelDeletion = String(localized: "account.cancelDeletion")
        static let cancelDeletionConfirmTitle = String(localized: "account.cancelDeletionConfirmTitle")
        static let cancelDeletionConfirmMessage = String(localized: "account.cancelDeletionConfirmMessage")
        static let deletionCancelled = String(localized: "account.deletionCancelled")
        static let deletionCancelFailed = String(localized: "account.deletionCancelFailed")
        static let error = String(localized: "account.error")
        static let errorSubtitle = String(localized: "account.errorSubtitle")
    }

    enum Premium {
        static let upgradeToPlus = String(localized: "premium.upgradeToPlus")
        static let unlockAnalytics = String(localized: "premium.unlockAnalytics")
    }

    enum Banner {
        static let warningCount = String(localized: "banner.warningCount")
    }
}
