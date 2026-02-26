import SwiftUI

struct AppToggle: View {
    @Binding var isOn: Bool
    let label: String
    var subtitle: String?

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey900)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                }
            }
        }
        .tint(AppColors.primary)
    }
}
