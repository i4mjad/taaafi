//
//  FamilyPickerView.swift
//  Runner
//
//  Created by Amjad Khalfan on 15/08/2025.
//

import SwiftUI
import FamilyControls

//TODO: consider looking for a way to localized all of those
struct FamilyPickerView: View {
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select apps & sites")
                .onAppear {
                    // Load saved selection when picker appears
                    if let savedSelection = FocusSelectionStore.load() {
                        selection = savedSelection
                        FocusLogger.d("FamilyPickerView loaded saved selection", "apps=\(savedSelection.applicationTokens.count) categories=\(savedSelection.categoryTokens.count)")
                    } else {
                        FocusLogger.d("FamilyPickerView no saved selection found")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            FocusSelectionStore.save(selection: selection)
                            FocusLogger.d("FamilyPickerView saved selection", "apps=\(selection.applicationTokens.count) categories=\(selection.categoryTokens.count)")
                            UIApplication.shared.topMostViewController()?.dismiss(animated: true)
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            FocusLogger.d("FamilyPickerView cancelled")
                            UIApplication.shared.topMostViewController()?.dismiss(animated: true)
                        }
                    }
                }
        }
    }
}
