//
//  UserReport.swift
//  ios
//

import Foundation
import FirebaseFirestore

enum ReportStatus: String, Codable, CaseIterable {
    case pending
    case inProgress = "in_progress"
    case waitingForAdminResponse = "waiting_for_admin_response"
    case closed
    case finalized
}

enum ReportType: String, CaseIterable, Identifiable {
    case dataError = "data_error"
    case communityFeedback = "community_feedback"
    case contactUs = "contact_us"
    case featureSuggestion = "feature_suggestion"
    case postReport = "post_report"
    case commentReport = "comment_report"
    case userReport = "user_report"
    case messageReport = "message_report"
    case groupUpdateReport = "group_update_report"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dataError: return String(localized: "report.type.dataError")
        case .communityFeedback: return String(localized: "report.type.communityFeedback")
        case .contactUs: return String(localized: "report.type.contactUs")
        case .featureSuggestion: return String(localized: "report.type.featureSuggestion")
        case .postReport: return String(localized: "report.type.postReport")
        case .commentReport: return String(localized: "report.type.commentReport")
        case .userReport: return String(localized: "report.type.userReport")
        case .messageReport: return String(localized: "report.type.messageReport")
        case .groupUpdateReport: return String(localized: "report.type.groupUpdateReport")
        }
    }

    var icon: String {
        switch self {
        case .dataError: return "exclamationmark.triangle"
        case .communityFeedback: return "bubble.left.and.bubble.right"
        case .contactUs: return "envelope"
        case .featureSuggestion: return "lightbulb"
        case .postReport: return "flag"
        case .commentReport: return "text.bubble"
        case .userReport: return "person.crop.circle.badge.exclamationmark"
        case .messageReport: return "message"
        case .groupUpdateReport: return "person.3"
        }
    }
}

struct UserReport: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var uid: String
    var time: Date
    var reportTypeId: String
    var status: ReportStatus
    var initialMessage: String
    var lastUpdated: Date
    var messagesCount: Int

    var reportType: ReportType? {
        ReportType(rawValue: reportTypeId)
    }
}
