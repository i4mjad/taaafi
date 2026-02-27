import SwiftUI

struct OngoingActivityWidget: View {
    let activity: OngoingActivity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(activity.activity?.name ?? "")
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey700)

                    Text("\(Strings.Vault.startDate): \(formattedDate)")
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(AppColors.grey200, lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: activity.progress)
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(activity.progress * 100))%")
                        .font(Typography.bodyTiny)
                        .foregroundStyle(AppColors.primary)
                }
                .frame(width: 44, height: 44)
            }
            .padding(Spacing.sm)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: activity.startDate)
    }
}
