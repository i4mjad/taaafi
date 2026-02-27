import SwiftUI

struct DayTaskWidget: View {
    let task: OngoingActivityTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? AppColors.success : AppColors.grey400)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.task?.name ?? "")
                    .font(Typography.body)
                    .foregroundStyle(task.isCompleted ? AppColors.grey400 : AppColors.grey700)
                    .strikethrough(task.isCompleted)

                if let description = task.task?.description, !description.isEmpty {
                    Text(description)
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let frequency = task.task?.frequency {
                Text(frequencyLabel(frequency))
                    .font(Typography.bodyTiny)
                    .foregroundStyle(AppColors.grey500)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(AppColors.grey100)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func frequencyLabel(_ frequency: TaskFrequency) -> String {
        switch frequency {
        case .daily: return Strings.Vault.daily
        case .weekly: return Strings.Vault.weekly
        case .monthly: return Strings.Vault.monthly
        }
    }
}
