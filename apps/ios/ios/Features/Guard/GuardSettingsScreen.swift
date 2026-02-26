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

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Circle()
                                .fill(colorFor(classifications[category] ?? .neutral))
                                .frame(width: 10, height: 10)
                            Text(category)
                                .font(Typography.body)
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(Typography.bodyTiny)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Picker("", selection: binding(for: category)) {
                            Text(Strings.Guard.safe).tag(CategoryClass.safe)
                            Text(Strings.Guard.neutral).tag(CategoryClass.neutral)
                            Text(Strings.Guard.threat).tag(CategoryClass.threat)
                        }
                        .pickerStyle(.segmented)
                        .disabled(isLocked)
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            } header: {
                Text(Strings.Guard.categoryClassifications)
            } footer: {
                Text(Strings.Guard.categoryFooter)
            }
        }
        .navigationTitle(Strings.Guard.settings)
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
        case .safe: return AppColors.success
        case .threat: return AppColors.error
        case .neutral: return AppColors.grey500
        }
    }
}

#Preview {
    NavigationStack {
        GuardSettingsScreen()
    }
}
