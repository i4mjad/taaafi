import Foundation
import FirebaseFirestore

/// Ported from: apps/mobile/lib/features/account/data/models/app_feature.dart

enum FeatureCategory: String, Codable {
    case core
    case social
    case content
    case communication
    case settings
}

struct AppFeature: Identifiable {
    let id: String
    let uniqueName: String
    let nameEn: String
    let nameAr: String
    let descriptionEn: String
    let descriptionAr: String
    let category: FeatureCategory
    let iconName: String
    let isActive: Bool
    let isBannable: Bool
    let createdAt: Date
    let updatedAt: Date

    func localizedName(languageCode: String) -> String {
        languageCode == "ar" ? nameAr : nameEn
    }

    func localizedDescription(languageCode: String) -> String {
        languageCode == "ar" ? descriptionAr : descriptionEn
    }

    static func generateUniqueName(from nameEn: String) -> String {
        nameEn
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    static func fromFirestore(_ document: DocumentSnapshot) -> AppFeature? {
        guard let data = document.data() else { return nil }

        return AppFeature(
            id: document.documentID,
            uniqueName: data["uniqueName"] as? String ?? "",
            nameEn: data["nameEn"] as? String ?? "",
            nameAr: data["nameAr"] as? String ?? "",
            descriptionEn: data["descriptionEn"] as? String ?? "",
            descriptionAr: data["descriptionAr"] as? String ?? "",
            category: FeatureCategory(rawValue: data["category"] as? String ?? "") ?? .core,
            iconName: data["iconName"] as? String ?? "",
            isActive: data["isActive"] as? Bool ?? true,
            isBannable: data["isBannable"] as? Bool ?? true,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
