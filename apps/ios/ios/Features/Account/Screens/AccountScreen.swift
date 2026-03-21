import SwiftUI
import FirebaseAuth

struct AccountScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(ToastManager.self) private var toastManager
    @Environment(FirestoreService.self) private var firestoreService

    @State private var viewModel: AccountViewModel?
    @State private var deletionManager: AccountDeletionManager?
    @State private var path = NavigationPath()
    @State private var showResetDataSheet = false
    @State private var showContactUsSheet = false
    @State private var showSignOutConfirmation = false
    @State private var showAppearanceSheet = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if userDocumentService.accountStatus == .pendingDeletion,
                       let manager = deletionManager {
                        PendingDeletionBanner(deletionManager: manager)
                    }

                    userHeader

                    settingsSection

                    dangerZoneSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .background(AppColors.grey50)
            .navigationTitle(Strings.Profile.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AccountNavigation.self) { destination in
                switch destination {
                case .userProfile:
                    UserProfileScreen()
                case .deleteAccount:
                    DeleteAccountScreen()
                }
            }
        }
        .task {
            viewModel = AccountViewModel(authService: authService)
            deletionManager = AccountDeletionManager(firestoreService: firestoreService)
        }
    }

    // MARK: - User Header

    private var userHeader: some View {
        Button {
            path.append(AccountNavigation.userProfile)
        } label: {
            UserHeaderCard(
                userDocument: userDocumentService.userDocument,
                userEmail: authService.currentUser?.email
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings

    private var currentAppearanceLabel: String {
        let theme = viewModel?.appTheme ?? "light"
        return theme == "dark" ? Strings.Profile.darkMode : Strings.Profile.lightMode
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Profile.settings)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)
                .padding(.horizontal, Spacing.xxs)
                .padding(.bottom, Spacing.xs)

            VStack(spacing: 0) {
                AccountSettingsRow(
                    icon: AppIcon.sunMax.systemName,
                    label: Strings.Profile.appearance
                ) {
                    showAppearanceSheet = true
                } trailing: {
                    HStack(spacing: Spacing.xs) {
                        Text(currentAppearanceLabel)
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.grey500)
                        Image(systemName: AppIcon.chevronForward.systemName)
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.grey400)
                    }
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.globe.systemName,
                    label: Strings.Profile.language
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.arrowCounterclockwise.systemName,
                    label: Strings.Profile.resetData
                ) {
                    showResetDataSheet = true
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.star.systemName,
                    label: Strings.Profile.appReview
                ) {
                    viewModel?.requestAppReview()
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.handRaised.systemName,
                    label: Strings.Profile.privacyPolicy
                ) {
                    openURL("https://taaafi.com/privacy")
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.docText.systemName,
                    label: Strings.Profile.termsOfService
                ) {
                    openURL("https://taaafi.com/terms")
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.paperplane.systemName,
                    label: Strings.Profile.contactUs
                ) {
                    showContactUsSheet = true
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .cardShadow()
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearanceSheet()
        }
        .sheet(isPresented: $showResetDataSheet) {
            ResetDataSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showContactUsSheet) {
            ContactUsSheet()
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Profile.dangerZone)
                .font(Typography.h6)
                .foregroundStyle(AppColors.error600)
                .padding(.horizontal, Spacing.xxs)
                .padding(.bottom, Spacing.xs)

            VStack(spacing: 0) {
                AccountSettingsRow(
                    icon: AppIcon.trash.systemName,
                    label: Strings.Profile.deleteAccount,
                    isDestructive: true
                ) {
                    path.append(AccountNavigation.deleteAccount)
                }

                Divider().padding(.horizontal, Spacing.md)

                AccountSettingsRow(
                    icon: AppIcon.signOut.systemName,
                    label: Strings.Common.signOut,
                    isDestructive: true
                ) {
                    showSignOutConfirmation = true
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .cardShadow()
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.error100, lineWidth: 1)
            )
        }
        .confirmationSheet(
            isPresented: $showSignOutConfirmation,
            icon: AppIcon.signOut.systemName,
            title: Strings.Profile.signOutConfirmTitle,
            message: Strings.Profile.signOutConfirmMessage,
            isDestructive: true,
            onResult: { confirmed in
                if confirmed {
                    viewModel?.signOut()
                }
            }
        )
    }

    // MARK: - Helpers

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
