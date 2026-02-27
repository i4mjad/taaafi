import SwiftUI

struct EmotionPickerView: View {
    @Binding var selectedEmotions: Set<String>

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(Strings.Vault.howDoYouFeel)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)

            // Negative emotions
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Strings.Vault.negativeFeelings)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)

                LazyVGrid(columns: columns, spacing: Spacing.xs) {
                    ForEach(Emotions.bad) { emotion in
                        emotionCell(emotion)
                    }
                }
            }

            // Positive emotions
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Strings.Vault.positiveFeelings)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)

                LazyVGrid(columns: columns, spacing: Spacing.xs) {
                    ForEach(Emotions.good) { emotion in
                        emotionCell(emotion)
                    }
                }
            }
        }
    }

    private func emotionCell(_ emotion: Emotion) -> some View {
        let isSelected = selectedEmotions.contains(emotion.id)

        return Button {
            if isSelected {
                selectedEmotions.remove(emotion.id)
            } else {
                selectedEmotions.insert(emotion.id)
            }
        } label: {
            VStack(spacing: 2) {
                Text(emotion.emoji)
                    .font(.system(size: 24))

                Text(String(localized: String.LocalizationValue(emotion.nameKey)))
                    .font(Typography.bodyTiny)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.grey500)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? AppColors.primary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
