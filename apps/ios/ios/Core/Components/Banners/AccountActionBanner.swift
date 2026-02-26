import SwiftUI

struct AccountActionBanner: View {
    let status: AccountStatus
    var onAction: () -> Void = {}
    var onSignOut: () -> Void = {}

    @Environment(FirestoreService.self) private var firestoreService

    var body: some View {
        Group {
            switch status {
            case .loading, .ok:
                EmptyView()

            case .pendingDeletion:
                PendingDeletionBanner(
                    deletionManager: AccountDeletionManager(firestoreService: firestoreService)
                )

            default:
                if let config = bannerConfig(for: status) {
                    standardBanner(config: config)
                }
            }
        }
    }

    private func standardBanner(config: BannerConfig) -> some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: config.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(config.iconColor)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(config.titleKey)
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(config.textColor)

                    Text(config.subtitleKey)
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                }

                Spacer()
            }

            HStack(spacing: Spacing.sm) {
                Button {
                    HapticService.lightImpact()
                    onAction()
                } label: {
                    Text(config.actionLabel)
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background(config.buttonColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Button {
                    HapticService.lightImpact()
                    onSignOut()
                } label: {
                    Text(Strings.Common.signOut)
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.error600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background(AppColors.error50)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
    }
}
