//
//  FamilyPickerView.swift
//  Runner
//
//  Created by Amjad Khalfan on 15/08/2025.
//

import SwiftUI
import FamilyControls

struct FamilyPickerView: View {
    @State private var selection = FamilyActivitySelection()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .onAppear {
                    FocusLogger.d("🟣 [PICKER] === FamilyPickerView: onAppear ===")
                    // Load saved selection when picker appears
                    if let savedSelection = FocusSelectionStore.load() {
                        selection = savedSelection
                        let appCount = savedSelection.applicationTokens.count
                        let catCount = savedSelection.categoryTokens.count
                        FocusLogger.d("🟣 [PICKER] FamilyPickerView: ✅ loaded saved selection - apps=\(appCount), categories=\(catCount)")
                    } else {
                        FocusLogger.d("🟣 [PICKER] FamilyPickerView: ℹ️ no saved selection found, starting fresh")
                    }
                }
                .onChange(of: selection) { newSelection in
                    let appCount = newSelection.applicationTokens.count
                    let catCount = newSelection.categoryTokens.count
                    FocusLogger.d("🟣 [PICKER] === onChange: START === apps=\(appCount), categories=\(catCount)")
                    
                    // Auto-save when selection changes
                    FocusSelectionStore.save(selection: newSelection)
                    FocusLogger.d("🟣 [PICKER] onChange: ✅ selection auto-saved")
                    FocusLogger.d("🟣 [PICKER] === onChange: END ===")
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            FocusLogger.d("🟣 [PICKER] === Done button: TAPPED ===")
                            let finalAppCount = selection.applicationTokens.count
                            let finalCatCount = selection.categoryTokens.count
                            FocusLogger.d("🟣 [PICKER] Done: final selection - apps=\(finalAppCount), categories=\(finalCatCount)")
                            FocusLogger.d("🟣 [PICKER] Done: dismissing picker...")
                            UIApplication.shared.topMostViewController()?.dismiss(animated: true)
                            FocusLogger.d("🟣 [PICKER] === Done button: COMPLETE ===")
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
