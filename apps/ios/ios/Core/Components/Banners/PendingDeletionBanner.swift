import SwiftUI
import FirebaseAuth

struct PendingDeletionBanner: View {
    @Bindable var deletionManager: AccountDeletionManager
    @Environment(ToastManager.self) private var toastManager

    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            header

            if let formattedDate = deletionManager.formattedDeletionDate {
                infoBox(formattedDate)
            }

            cancelButton
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
        .task {
            if let userId = Auth.auth().currentUser?.uid {
                await deletionManager.fetchDeletionDate(userId: userId)
            }
        }
        .confirmationSheet(
            isPresented: $showConfirmation,
            icon: AppIcon.userX.systemName,
            title: Strings.Account.cancelDeletionConfirmTitle,
            message: Strings.Account.cancelDeletionConfirmMessage,
            isDestructive: false,
            onResult: { confirmed in
                if confirmed {
                    Task { await handleCancelDeletion() }
                }
            }
        )
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: AppIcon.userX.systemName)
                .font(.system(size: 24))
                .foregroundStyle(AppColors.error600)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Strings.Account.pendingDeletion)
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.error800)

                Text(Strings.Account.pendingDeletionSubtitle)
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey500)
            }

            Spacer()
        }
    }

    private func infoBox(_ formattedDate: String) -> some View {
        HStack {
            Image(systemName: AppIcon.info.systemName)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.warning700)

            Text(String(format: Strings.Account.deletionScheduled, formattedDate))
                .font(Typography.caption)
                .foregroundStyle(AppColors.warning800)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warning50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.warning200, lineWidth: 1)
        )
    }

    private var cancelButton: some View {
        Button {
            HapticService.lightImpact()
            showConfirmation = true
        } label: {
            Group {
                if deletionManager.isCancelling {
                    AppSpinner(tint: .white)
                } else {
                    Text(Strings.Account.cancelDeletion)
                }
            }
            .font(Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(AppColors.success600)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .disabled(deletionManager.isCancelling)
    }

    private func handleCancelDeletion() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let success = await deletionManager.cancelDeletion(userId: userId)
        if success {
            toastManager.show(.success, message: Strings.Account.deletionCancelled)
        } else {
            toastManager.show(.error, message: Strings.Account.deletionCancelFailed)
        }
    }
}
