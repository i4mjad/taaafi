//
//  FocusSelectionStore.swift
//  Runner
//
//  Created by Amjad Khalfan on 15/08/2025.
//

import Foundation
import FamilyControls

enum FocusSelectionStore {
    private static let key = "familySelection"

    static func save(selection: FamilyActivitySelection) {
        // Persist minimal opaque data, not PII.
        do {
            // FamilyActivitySelection is Codable in modern SDKs; if not, store tokens separately.
            let data = try JSONEncoder().encode(selection)
            UserDefaults(suiteName: FocusShared.appGroupId)?.set(data, forKey: key)
        } catch {
            // fallback: store empty
            UserDefaults(suiteName: FocusShared.appGroupId)?.removeObject(forKey: key)
        }
    }

    static func load() -> FamilyActivitySelection? {
        guard let data = UserDefaults(suiteName: FocusShared.appGroupId)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
