//
//  CategoryClassification.swift
//  ios
//
//  Created by Amjad Khalfan on 21/02/2026.
//

import Foundation

enum CategoryClass: String, CaseIterable, Codable {
    case safe
    case threat
    case neutral
}

struct CategoryClassification {
    static let defaultsKey = "categoryClassifications"
    static let suiteName = "group.com.taaafi.app"

    static let defaults: [String: CategoryClass] = [
        "Social Networking": .threat,
        "Social": .threat,
        "Entertainment": .threat,
        "Games": .threat,
        "Productivity & Finance": .safe,
        "Productivity": .safe,
        "Education": .safe,
        "Health & Fitness": .safe,
        "Creativity": .safe,
        "Other": .neutral,
        "Information & Reading": .neutral,
        "System": .neutral,
    ]

    static func current() -> [String: CategoryClass] {
        var result = defaults
        if let store = UserDefaults(suiteName: suiteName),
           let saved = store.dictionary(forKey: defaultsKey) as? [String: String] {
            for (key, value) in saved {
                if let cls = CategoryClass(rawValue: value) {
                    result[key] = cls
                }
            }
        }
        return result
    }

    static func save(_ map: [String: CategoryClass]) {
        guard let store = UserDefaults(suiteName: suiteName) else { return }
        let dict = map.mapValues { $0.rawValue }
        store.set(dict, forKey: defaultsKey)
    }

    static func classify(_ categoryName: String) -> CategoryClass {
        current()[categoryName] ?? .neutral
    }
}
