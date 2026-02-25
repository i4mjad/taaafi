//
//  CategoryClassification.swift
//  DeviceActivityReport
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

    static let lockedCategories: Set<String> = [
        "Social Networking",
        "Social",
    ]

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
        "Business": .safe,
        "Developer Tools": .safe,
        "Finance": .safe,
        "Graphics & Design": .safe,
        "Reference": .safe,
        "Book": .safe,
        "Books": .safe,
        "Information & Reading": .neutral,
        "Shopping": .neutral,
        "Travel": .neutral,
        "Food & Drink": .neutral,
        "Sports": .neutral,
        "Weather": .neutral,
        "Lifestyle": .neutral,
        "Magazines & Newspapers": .neutral,
        "Medical": .neutral,
        "Music": .neutral,
        "Navigation": .neutral,
        "News": .neutral,
        "Photo & Video": .neutral,
        "Utilities": .neutral,
        "Stickers": .neutral,
        "Kids": .neutral,
        "Other": .neutral,
        "System": .neutral,
    ]

    static func current() -> [String: CategoryClass] {
        var result = defaults
        if let store = UserDefaults(suiteName: suiteName),
           let saved = store.dictionary(forKey: defaultsKey) as? [String: String] {
            for (key, value) in saved {
                guard !lockedCategories.contains(key) else { continue }
                if let cls = CategoryClass(rawValue: value) {
                    result[key] = cls
                }
            }
        }
        return result
    }

    static func save(_ map: [String: CategoryClass]) {
        guard let store = UserDefaults(suiteName: suiteName) else { return }
        var filtered = map
        for locked in lockedCategories {
            filtered[locked] = defaults[locked]
        }
        let dict = filtered.mapValues { $0.rawValue }
        store.set(dict, forKey: defaultsKey)
    }

    static func classify(_ categoryName: String) -> CategoryClass {
        current()[categoryName] ?? .neutral
    }
}
