import SwiftUI
import FirebaseAuth

struct DeleteAccountScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(CloudFunctionsService.self) private var cloudFunctionsService
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(ToastManager.self) private var toastManager

    @State private var viewModel: DeleteAccountViewModel?
    @State private var detailsText = ""
    @State private var showDeleteConfirmation = false

    private var isPlusUser: Bool { userDocumentService.userDocument?.isPlusUser ?? false }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                DeletionInfoSection()

                reasonHeader

                if viewModel?.shouldShowRetentionOffer(hasActiveSubscription: isPlusUser) == true {
                    RetentionOfferCard(
                        onClaim: { Task { await viewModel?.claimRetentionReward() } },
                        onSkip: { viewModel?.skipRetentionOffer() },
                        isClaiming: viewModel?.isClaimingReward ?? false
                    )
                } else {
                    reasonSelection

                    if viewModel?.showDetails == true {
                        detailsField
                    }

                    if isPlusUser {
                        subscriptionWarning
                    }

                    finalWarning

                    if viewModel?.hasSkippedOffer == true {
                        reconsiderLink
                    }

                    deleteButton
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(AppColors.grey50)
        .navigationTitle(Strings.Profile.deleteAccountTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let user = authService.currentUser else { return }
            viewModel = DeleteAccountViewModel(
                cloudFunctionsService: cloudFunctionsService,
                firestoreService: firestoreService,
                authService: authService,
                userId: user.uid,
                userEmail: user.email ?? "",
                userName: userDocumentService.userDocument?.displayName ?? ""
            )
            await viewModel?.checkRetentionRewardStatus()
        }
        .confirmationSheet(
            isPresented: $showDeleteConfirmation,
            icon: AppIcon.trash.systemName,
            title: Strings.Profile.deleteConfirmTitle,
            message: Strings.Profile.deleteConfirmMessage,
            confirmLabel: Strings.Profile.deleteButton,
            isDestructive: true,
            onResult: { confirmed in
                if confirmed { Task { await handleDelete() } }
            }
        )
    }

    // MARK: - Reason Header

    private var reasonHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.selectReason)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)

            Text(Strings.Profile.selectReasonSubtitle)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reason Selection

    private var reasonSelection: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(DeletionReason.allReasons) { reason in
                Button {
                    viewModel?.selectReason(reason.id)
                } label: {
                    reasonCard(reason)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reasonCard(_ reason: DeletionReason) -> some View {
        let isSelected = viewModel?.selectedReasonId == reason.id
        return HStack(spacing: Spacing.sm) {
            Image(systemName: isSelected ? AppIcon.radioButtonFilled.systemName : AppIcon.radioButton.systemName)
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? AppColors.primary600 : AppColors.grey400)

            Text(String(localized: String.LocalizationValue(reason.translationKey)))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey900)

            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(isSelected ? AppColors.primary50 : AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? AppColors.primary600 : AppColors.grey200, lineWidth: 1)
        )
        .accessibilityLabel(String(localized: String.LocalizationValue(reason.translationKey)))
    }

    // MARK: - Details

    private var detailsField: some View {
        AppTextArea(
            text: $detailsText,
            label: Strings.Profile.additionalDetails,
            maxLength: 300
        )
        .onChange(of: detailsText) { _, newValue in
            viewModel?.detailsText = newValue
        }
    }

    // MARK: - Subscription Warning

    private var subscriptionWarning: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: AppIcon.alertTriangle.systemName)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.warning700)

            Text(Strings.Profile.subscriptionWarning)
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

    // MARK: - Final Warning

    private var finalWarning: some View {
        Text(Strings.Profile.finalWarning)
            .font(Typography.small)
            .foregroundStyle(AppColors.grey500)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.md)
    }

    // MARK: - Reconsider

    private var reconsiderLink: some View {
        Button {
            viewModel?.hasSkippedOffer = false
        } label: {
            Text(Strings.Profile.reconsider)
                .font(Typography.caption)
                .foregroundStyle(AppColors.primary600)
                .underline()
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Group {
                if viewModel?.isSubmitting == true {
                    AppSpinner(tint: .white)
                } else {
                    Text(Strings.Profile.deleteButton)
                }
            }
            .font(Typography.body)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(viewModel?.canSubmit == true && !isPlusUser ? AppColors.error600 : AppColors.grey300)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(viewModel?.canSubmit != true || isPlusUser || viewModel?.isSubmitting == true)
        .accessibilityLabel(Strings.Profile.deleteButton)
    }

    // MARK: - Actions

    private func handleDelete() async {
        guard let result = await viewModel?.submitDeletionRequest(), result else {
            toastManager.show(.error, message: Strings.Account.error)
            return
        }
    }
}
