import SwiftUI

struct TriggerPickerView: View {
    @Binding var selectedTriggers: Set<String>

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.Vault.whatTriggeredYou)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(CommonTriggers.all, id: \.key) { trigger in
                    triggerCell(key: trigger.key, icon: trigger.icon)
                }
            }
        }
    }

    private func triggerCell(key: String, icon: String) -> some View {
        let isSelected = selectedTriggers.contains(key)
        let triggerLabel = localizedTrigger(key)

        return Button {
            if isSelected {
                selectedTriggers.remove(key)
            } else {
                selectedTriggers.insert(key)
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(triggerLabel)
                    .font(Typography.footnote)
            }
            .foregroundStyle(isSelected ? .white : AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? AppColors.primary : AppColors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func localizedTrigger(_ key: String) -> String {
        String(localized: String.LocalizationValue("vault.trigger.\(key)"))
    }
}
