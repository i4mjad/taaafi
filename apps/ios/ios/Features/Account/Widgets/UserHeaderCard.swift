import SwiftUI

struct UserHeaderCard: View {
    let userDocument: UserDocument?
    let userEmail: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                avatar

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(userDocument?.displayName ?? "")
                        .font(Typography.h6)
                        .foregroundStyle(AppColors.grey900)

                    Text(userEmail ?? userDocument?.email ?? "")
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey500)

                    if let age = userAge {
                        Text("\(age) \(Strings.Profile.yearsOld)")
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.grey500)
                    }

                    planBadge
                }
            }

            Spacer()

            Image(systemName: AppIcon.chevronForward.systemName)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.grey400)
        }
        .padding(Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .cardShadow()
        .accessibilityLabel("\(userDocument?.displayName ?? ""), \(userEmail ?? "")")
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary50)
                .frame(width: 48, height: 48)

            Image(systemName: AppIcon.person.systemName)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary600)
        }
    }

    // MARK: - Plan Badge

    private var planBadge: some View {
        let isPlus = userDocument?.isPlusUser == true

        return HStack(spacing: Spacing.xxs) {
            Image(systemName: isPlus ? AppIcon.star.systemName : AppIcon.person.systemName)
                .font(.system(size: 12))
                .foregroundStyle(isPlus ? AppColors.primary600 : AppColors.grey500)

            Text(isPlus ? Strings.Profile.plusActive : Strings.Profile.freePlan)
                .font(Typography.small)
                .fontWeight(.semibold)
                .foregroundStyle(isPlus ? AppColors.primary700 : AppColors.grey500)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isPlus ? AppColors.primary100 : AppColors.grey100)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(isPlus ? AppColors.primary300 : AppColors.grey300, lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private var userAge: Int? {
        guard let dob = userDocument?.dayOfBirth else { return nil }
        let components = Calendar.current.dateComponents([.year], from: dob, to: Date())
        return components.year
    }
}
