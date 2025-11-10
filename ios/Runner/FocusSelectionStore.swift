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
        FocusLogger.d("🟡 [STORE] === save: START ===")
        let appCount = selection.applicationTokens.count
        let catCount = selection.categoryTokens.count
        FocusLogger.d("🟡 [STORE] save: encoding selection - apps=\(appCount), categories=\(catCount)")
        
        do {
            let data = try JSONEncoder().encode(selection)
            FocusLogger.d("🟡 [STORE] save: encoded \(data.count) bytes")
            
            guard let ud = UserDefaults(suiteName: FocusShared.appGroupId) else {
                FocusLogger.e("🟡 [STORE] save: ❌ ERROR - cannot access app group '\(FocusShared.appGroupId)'")
                return
            }
            
            ud.set(data, forKey: key)
            FocusLogger.d("🟡 [STORE] save: ✅ saved to app group successfully")
        } catch {
            FocusLogger.e("🟡 [STORE] save: ❌ ERROR encoding - \(error.localizedDescription)")
            UserDefaults(suiteName: FocusShared.appGroupId)?.removeObject(forKey: key)
        }
        
        FocusLogger.d("🟡 [STORE] === save: END ===")
    }

    static func load() -> FamilyActivitySelection? {
        FocusLogger.d("🟡 [STORE] === load: START ===")
        
        guard let ud = UserDefaults(suiteName: FocusShared.appGroupId) else {
            FocusLogger.e("🟡 [STORE] load: ❌ ERROR - cannot access app group '\(FocusShared.appGroupId)'")
            return nil
        }
        
        guard let data = ud.data(forKey: key) else {
            FocusLogger.d("🟡 [STORE] load: ℹ️ no saved selection found (empty)")
            return nil
        }
        
        FocusLogger.d("🟡 [STORE] load: found \(data.count) bytes, decoding...")
        
        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            let appCount = selection.applicationTokens.count
            let catCount = selection.categoryTokens.count
            FocusLogger.d("🟡 [STORE] load: ✅ decoded successfully - apps=\(appCount), categories=\(catCount)")
            FocusLogger.d("🟡 [STORE] === load: END ===")
            return selection
        } catch {
            FocusLogger.e("🟡 [STORE] load: ❌ ERROR decoding - \(error.localizedDescription)")
            FocusLogger.d("🟡 [STORE] === load: END ===")
            return nil
        }
    }
}
