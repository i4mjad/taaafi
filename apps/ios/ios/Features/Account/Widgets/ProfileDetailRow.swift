import SwiftUI

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.grey500)
                .frame(width: 20, alignment: .center)

            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey800)

            Spacer()
        }
    }
}
