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
                    // Load saved selection when picker appears
                    if let savedSelection = FocusSelectionStore.load() {
                        selection = savedSelection
                        FocusLogger.d("FamilyPickerView loaded saved selection", "apps=\(savedSelection.applicationTokens.count) categories=\(savedSelection.categoryTokens.count)")
                    } else {
                        FocusLogger.d("FamilyPickerView no saved selection found")
                    }
                }
                .onChange(of: selection) { newSelection in
                    // Auto-save when selection changes
                    FocusSelectionStore.save(selection: newSelection)
                    FocusLogger.d("FamilyPickerView auto-saved selection", "apps=\(newSelection.applicationTokens.count) categories=\(newSelection.categoryTokens.count)")
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            FocusLogger.d("FamilyPickerView done tapped")
                            UIApplication.shared.topMostViewController()?.dismiss(animated: true)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
