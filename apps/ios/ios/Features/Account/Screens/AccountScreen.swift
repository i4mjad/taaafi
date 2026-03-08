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

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if userDocumentService.accountStatus == .pendingDeletion,
                       let manager = deletionManager {
                        PendingDeletionBanner(deletionManager: manager)
                    }

                    userHeader

                    appearanceSection

                    languageSection

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

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.Profile.appearance)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)
                .padding(.horizontal, Spacing.xxs)

            HStack(spacing: Spacing.sm) {
                themeCard(
                    icon: AppIcon.sunMax.systemName,
                    label: Strings.Profile.lightMode,
                    theme: "light"
                )
                themeCard(
                    icon: AppIcon.moon.systemName,
                    label: Strings.Profile.darkMode,
                    theme: "dark"
                )
            }
        }
    }

    private func themeCard(icon: String, label: String, theme: String) -> some View {
        let isSelected = viewModel?.appTheme == theme
        return Button {
            viewModel?.appTheme = theme
            applyTheme(theme)
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? AppColors.primary600 : AppColors.grey500)
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(isSelected ? AppColors.primary600 : AppColors.grey600)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? AppColors.primary50 : AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.primary600 : AppColors.grey200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func applyTheme(_ theme: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in scene.windows {
            window.overrideUserInterfaceStyle = theme == "light" ? .light : theme == "dark" ? .dark : .unspecified
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.Profile.language)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)
                .padding(.horizontal, Spacing.xxs)

            HStack(spacing: Spacing.sm) {
                languageButton(label: Strings.Profile.arabic, locale: "ar")
                languageButton(label: Strings.Profile.english, locale: "en")
            }
        }
    }

    private func languageButton(label: String, locale: String) -> some View {
        let isSelected = userDocumentService.userDocument?.locale == locale
        return Button {
            guard let uid = authService.currentUser?.uid else { return }
            Task {
                try? await userDocumentService.updateUserDocument(userId: uid, fields: ["locale": locale])
            }
        } label: {
            Text(label)
                .font(Typography.body)
                .foregroundStyle(isSelected ? AppColors.primary600 : AppColors.grey600)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? AppColors.primary50 : AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? AppColors.primary600 : AppColors.grey200, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Profile.settings)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)
                .padding(.horizontal, Spacing.xxs)
                .padding(.bottom, Spacing.xs)

            VStack(spacing: 0) {
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
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.grey200, lineWidth: 1)
            )
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
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
