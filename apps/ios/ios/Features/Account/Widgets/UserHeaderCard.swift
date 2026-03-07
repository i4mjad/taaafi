import SwiftUI

struct UserHeaderCard: View {
    let userDocument: UserDocument?
    let userEmail: String?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            avatar

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(userDocument?.displayName ?? "")
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey900)

                Text(userEmail ?? userDocument?.email ?? "")
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
            }

            Spacer()

            Image(systemName: AppIcon.chevronRight.systemName)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.grey400)
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
        .accessibilityLabel("\(userDocument?.displayName ?? ""), \(userEmail ?? "")")
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary50)
                .frame(width: 64, height: 64)

            Image(systemName: AppIcon.person.systemName)
                .font(.system(size: 24))
                .foregroundStyle(AppColors.primary600)
        }
    }
}
