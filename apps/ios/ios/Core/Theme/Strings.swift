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
        static let ok = String(localized: "common.ok")
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

    enum Auth {
        static let email = String(localized: "auth.email")
        static let enterEmail = String(localized: "auth.enterEmail")
        static let password = String(localized: "auth.password")
        static let login = String(localized: "auth.login")
        static let signUp = String(localized: "auth.signUp")
        static let forgotPassword = String(localized: "auth.forgotPassword")
        static let forgotPasswordTitle = String(localized: "auth.forgotPasswordTitle")
        static let forgotPasswordDescription = String(localized: "auth.forgotPasswordDescription")
        static let sendResetLink = String(localized: "auth.sendResetLink")
        static let resetLinkSent = String(localized: "auth.resetLinkSent")
        static let signInWithGoogle = String(localized: "auth.signInWithGoogle")
        static let noAccount = String(localized: "auth.noAccount")
        static let or = String(localized: "auth.or")
        static let fillAllFields = String(localized: "auth.fillAllFields")
        static let errorTitle = String(localized: "auth.errorTitle")
        static let errorMessage = String(localized: "auth.errorMessage")
    }

    enum Onboarding {
        static let getStarted = String(localized: "onboarding.getStarted")
        static let signIn = String(localized: "onboarding.signIn")
    }

    enum Registration {
        static let credentialsTitle = String(localized: "registration.credentialsTitle")
        static let profileTitle = String(localized: "registration.profileTitle")
        static let languageTitle = String(localized: "registration.languageTitle")
        static let languageDescription = String(localized: "registration.languageDescription")
        static let recoveryDateTitle = String(localized: "registration.recoveryDateTitle")
        static let recoveryDateDescription = String(localized: "registration.recoveryDateDescription")
        static let emailVerificationTitle = String(localized: "registration.emailVerificationTitle")
        static let emailVerificationDescription = String(localized: "registration.emailVerificationDescription")
        static let emailVerified = String(localized: "registration.emailVerified")
        static let referralTitle = String(localized: "registration.referralTitle")
        static let referralDescription = String(localized: "registration.referralDescription")
        static let referralCode = String(localized: "registration.referralCode")
        static let termsTitle = String(localized: "registration.termsTitle")
        static let acceptTerms = String(localized: "registration.acceptTerms")
        static let viewTerms = String(localized: "registration.viewTerms")
        static let confirmPassword = String(localized: "registration.confirmPassword")
        static let name = String(localized: "registration.name")
        static let dateOfBirth = String(localized: "registration.dateOfBirth")
        static let gender = String(localized: "registration.gender")
        static let male = String(localized: "registration.male")
        static let female = String(localized: "registration.female")
        static let arabic = String(localized: "registration.arabic")
        static let english = String(localized: "registration.english")
        static let startFromNow = String(localized: "registration.startFromNow")
        static let chooseDate = String(localized: "registration.chooseDate")
        static let recoveryStartDate = String(localized: "registration.recoveryStartDate")
        static let resendEmail = String(localized: "registration.resendEmail")
        static let skip = String(localized: "registration.skip")
        static let next = String(localized: "registration.next")
        static let back = String(localized: "registration.back")
        static let submit = String(localized: "registration.submit")
        static let invalidEmail = String(localized: "registration.invalidEmail")
        static let weakPassword = String(localized: "registration.weakPassword")
        static let passwordMismatch = String(localized: "registration.passwordMismatch")
        static let nameRequired = String(localized: "registration.nameRequired")
    }

    enum ConfirmDetails {
        static let title = String(localized: "confirmDetails.title")
        static let description = String(localized: "confirmDetails.description")
        static let save = String(localized: "confirmDetails.save")
        static let saved = String(localized: "confirmDetails.saved")
    }

    enum ConfirmEmail {
        static let title = String(localized: "confirmEmail.title")
        static let description = String(localized: "confirmEmail.description")
        static let checkVerification = String(localized: "confirmEmail.checkVerification")
        static let resend = String(localized: "confirmEmail.resend")
        static let verified = String(localized: "confirmEmail.verified")
        static let changeEmail = String(localized: "confirmEmail.changeEmail")
        static let changeEmailTitle = String(localized: "confirmEmail.changeEmailTitle")
        static let changeEmailDescription = String(localized: "confirmEmail.changeEmailDescription")
        static let newEmail = String(localized: "confirmEmail.newEmail")
        static let updateEmail = String(localized: "confirmEmail.updateEmail")
        static let emailChangeSent = String(localized: "confirmEmail.emailChangeSent")
    }

    enum Paywall {
        static let title = String(localized: "paywall.title")
        static let subtitle = String(localized: "paywall.subtitle")
        static let subscribe = String(localized: "paywall.subscribe")
        static let maybeLater = String(localized: "paywall.maybeLater")
        static let comingSoon = String(localized: "paywall.comingSoon")
        static let comingSoonMessage = String(localized: "paywall.comingSoonMessage")
    }

    enum Home {
        static let welcomeBack = String(localized: "home.welcomeBack")
        static let comingSoon = String(localized: "home.comingSoon")
        static let quickActions = String(localized: "home.quickActions")
        static let streaks = String(localized: "home.streaks")
        static let calendar = String(localized: "home.calendar")
        static let community = String(localized: "home.community")
    }

    enum Ban {
        static let deviceRestricted = String(localized: "ban.deviceRestricted")
        static let accountRestricted = String(localized: "ban.accountRestricted")
        static let details = String(localized: "ban.details")
        static let scopeAppWide = String(localized: "ban.scopeAppWide")
        static let scopeFeature = String(localized: "ban.scopeFeature")
        static let typeUser = String(localized: "ban.typeUser")
        static let typeDevice = String(localized: "ban.typeDevice")
        static let typeFeature = String(localized: "ban.typeFeature")
        static let reason = String(localized: "ban.reason")
        static let description = String(localized: "ban.description")
        static let duration = String(localized: "ban.duration")
        static let issuedDate = String(localized: "ban.issuedDate")
        static let expiresOn = String(localized: "ban.expiresOn")
        static let banId = String(localized: "ban.banId")
        static let permanent = String(localized: "ban.permanent")
        static let unknown = String(localized: "ban.unknown")
        static let expired = String(localized: "ban.expired")
        static let checkBanStatus = String(localized: "ban.checkBanStatus")
        static let deviceBanNoLogoutMessage = String(localized: "ban.deviceBanNoLogoutMessage")
        static let unableToLoadDetails = String(localized: "ban.unableToLoadDetails")
        static let accountRestrictedMessage = String(localized: "ban.accountRestrictedMessage")
        static let devicePermanentlyRestricted = String(localized: "ban.devicePermanentlyRestricted")
        static let appealInfo = String(localized: "ban.appealInfo")
        static let day = String(localized: "ban.day")
        static let days = String(localized: "ban.days")
        static let hour = String(localized: "ban.hour")
        static let hours = String(localized: "ban.hours")
        static let minute = String(localized: "ban.minute")
        static let minutes = String(localized: "ban.minutes")
    }

    enum Report {
        static let title = String(localized: "reports.title")
        static let empty = String(localized: "reports.empty")
        static let emptySubtitle = String(localized: "reports.emptySubtitle")
        static let errorLoading = String(localized: "reports.errorLoading")
    }
}
