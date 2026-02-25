//
//  GuardSettingsScreen.swift
//  ios
//
//  Created by Amjad Khalfan on 21/02/2026.
//

import SwiftUI

struct GuardSettingsScreen: View {
    @State private var classifications: [String: CategoryClass] = CategoryClassification.current()

    var body: some View {
        List {
            Section {
                ForEach(CategoryClassification.allCategories, id: \.self) { category in
                    let isLocked = CategoryClassification.lockedCategories.contains(category)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(colorFor(classifications[category] ?? .neutral))
                                .frame(width: 10, height: 10)
                            Text(category)
                                .font(.body)
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Picker("", selection: binding(for: category)) {
                            Text("Safe").tag(CategoryClass.safe)
                            Text("Neutral").tag(CategoryClass.neutral)
                            Text("Threat").tag(CategoryClass.threat)
                        }
                        .pickerStyle(.segmented)
                        .disabled(isLocked)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Category Classifications")
            } footer: {
                Text("Threat categories count against your Guard Score. Safe categories improve it. Neutral categories are excluded. Social categories are locked as threats.")
            }
        }
        .navigationTitle("Guard Settings")
    }

    private func binding(for category: String) -> Binding<CategoryClass> {
        Binding(
            get: { classifications[category] ?? .neutral },
            set: { newValue in
                guard !CategoryClassification.lockedCategories.contains(category) else { return }
                classifications[category] = newValue
                CategoryClassification.save(classifications)
            }
        )
    }

    private func colorFor(_ cls: CategoryClass) -> Color {
        switch cls {
        case .safe: return .green
        case .threat: return .red
        case .neutral: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        GuardSettingsScreen()
    }
}
