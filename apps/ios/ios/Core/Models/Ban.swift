import Foundation
import FirebaseFirestore

/// Ported from: apps/mobile/lib/features/account/data/models/ban.dart

enum BanType: String, Codable {
    case user_ban
    case device_ban
    case feature_ban
}

enum BanScope: String, Codable {
    case app_wide
    case feature_specific
}

enum BanSeverity: String, Codable {
    case temporary
    case permanent
}

struct RelatedContent: Codable {
    let type: String   // 'user', 'report', 'post', 'comment', 'message', 'group', 'other'
    let id: String
    let title: String?
    let metadata: [String: String]?
}

struct Ban: Identifiable {
    let id: String
    let userId: String
    let type: BanType
    let scope: BanScope
    let reason: String
    let description: String?
    let severity: BanSeverity
    let issuedBy: String
    let issuedAt: Date
    let expiresAt: Date?
    let isActive: Bool
    let restrictedFeatures: [String]?
    let restrictedDevices: [String]?
    let deviceIds: [String]?
    let relatedContent: RelatedContent?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date.now > expiresAt
    }

    var isCurrentlyActive: Bool {
        isActive && !isExpired
    }

    static func fromFirestore(_ document: DocumentSnapshot) -> Ban? {
        guard let data = document.data() else { return nil }

        return Ban(
            id: document.documentID,
            userId: data["userId"] as? String ?? "",
            type: BanType(rawValue: data["type"] as? String ?? "") ?? .user_ban,
            scope: BanScope(rawValue: data["scope"] as? String ?? "") ?? .app_wide,
            reason: data["reason"] as? String ?? "",
            description: data["description"] as? String,
            severity: BanSeverity(rawValue: data["severity"] as? String ?? "") ?? .permanent,
            issuedBy: data["issuedBy"] as? String ?? "",
            issuedAt: (data["issuedAt"] as? Timestamp)?.dateValue() ?? Date(),
            expiresAt: (data["expiresAt"] as? Timestamp)?.dateValue(),
            isActive: data["isActive"] as? Bool ?? true,
            restrictedFeatures: data["restrictedFeatures"] as? [String],
            restrictedDevices: data["restrictedDevices"] as? [String],
            deviceIds: data["deviceIds"] as? [String],
            relatedContent: {
                guard let rc = data["relatedContent"] as? [String: Any] else { return nil }
                return RelatedContent(
                    type: rc["type"] as? String ?? "",
                    id: rc["id"] as? String ?? "",
                    title: rc["title"] as? String,
                    metadata: rc["metadata"] as? [String: String]
                )
            }()
        )
    }
}
