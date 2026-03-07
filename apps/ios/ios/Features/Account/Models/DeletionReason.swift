import Foundation

enum DeletionReasonCategory: String, Codable {
    case privacy
    case usability
    case satisfaction
    case other
}

struct DeletionReason: Identifiable, Hashable {
    let id: String
    let translationKey: String
    let category: DeletionReasonCategory
    let requiresDetails: Bool

    static let allReasons: [DeletionReason] = [
        DeletionReason(id: "privacy_concerns", translationKey: "profile.deleteReason.privacyConcerns", category: .privacy, requiresDetails: false),
        DeletionReason(id: "data_security", translationKey: "profile.deleteReason.dataSecurity", category: .privacy, requiresDetails: false),
        DeletionReason(id: "not_helpful", translationKey: "profile.deleteReason.notHelpful", category: .satisfaction, requiresDetails: false),
        DeletionReason(id: "too_complex", translationKey: "profile.deleteReason.tooComplex", category: .usability, requiresDetails: false),
        DeletionReason(id: "technical_issues", translationKey: "profile.deleteReason.technicalIssues", category: .usability, requiresDetails: true),
        DeletionReason(id: "no_longer_needed", translationKey: "profile.deleteReason.noLongerNeeded", category: .satisfaction, requiresDetails: false),
        DeletionReason(id: "switching_apps", translationKey: "profile.deleteReason.switchingApps", category: .satisfaction, requiresDetails: false),
        DeletionReason(id: "temporary_break", translationKey: "profile.deleteReason.temporaryBreak", category: .satisfaction, requiresDetails: false),
        DeletionReason(id: "missing_features", translationKey: "profile.deleteReason.missingFeatures", category: .usability, requiresDetails: true),
        DeletionReason(id: "content_inappropriate", translationKey: "profile.deleteReason.contentInappropriate", category: .satisfaction, requiresDetails: true),
        DeletionReason(id: "poor_support", translationKey: "profile.deleteReason.poorSupport", category: .satisfaction, requiresDetails: false),
        DeletionReason(id: "other", translationKey: "profile.deleteReason.other", category: .other, requiresDetails: true),
    ]

    static func findById(_ id: String) -> DeletionReason? {
        allReasons.first { $0.id == id }
    }
}
