import Foundation
import FirebaseFirestore

/// Ported from: apps/mobile/lib/features/account/data/models/warning.dart

enum WarningType: String, Codable {
    case content_violation
    case inappropriate_behavior
    case spam
    case harassment
    case other
}

enum WarningSeverity: String, Codable {
    case low
    case medium
    case high
    case critical
}

struct Warning: Identifiable {
    let id: String
    let userId: String
    let type: WarningType
    let reason: String
    let description: String?
    let severity: WarningSeverity
    let issuedBy: String
    let issuedAt: Date
    let isActive: Bool
    let deviceIds: [String]?
    let relatedContent: RelatedContent?
    let reportId: String?

    static func fromFirestore(_ document: DocumentSnapshot) -> Warning? {
        guard let data = document.data() else { return nil }

        return Warning(
            id: document.documentID,
            userId: data["userId"] as? String ?? "",
            type: WarningType(rawValue: data["type"] as? String ?? "") ?? .other,
            reason: data["reason"] as? String ?? "",
            description: data["description"] as? String,
            severity: WarningSeverity(rawValue: data["severity"] as? String ?? "") ?? .low,
            issuedBy: data["issuedBy"] as? String ?? "",
            issuedAt: (data["issuedAt"] as? Timestamp)?.dateValue() ?? Date(),
            isActive: data["isActive"] as? Bool ?? true,
            deviceIds: data["deviceIds"] as? [String],
            relatedContent: {
                guard let rc = data["relatedContent"] as? [String: Any] else { return nil }
                return RelatedContent(
                    type: rc["type"] as? String ?? "",
                    id: rc["id"] as? String ?? "",
                    title: rc["title"] as? String,
                    metadata: rc["metadata"] as? [String: String]
                )
            }(),
            reportId: data["reportId"] as? String
        )
    }
}
