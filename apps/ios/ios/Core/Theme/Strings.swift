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
    }
}
