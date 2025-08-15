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
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            FocusSelectionStore.save(selection: selection)
                            UIApplication.shared.topMostViewController()?.dismiss(animated: true)
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            UIApplication.shared.topMostViewController()?.dismiss(animated: true)
                        }
                    }
                }
        }
    }
}
