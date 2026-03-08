import SwiftUI
import FirebaseAuth

struct UserProfileScreen: View {
    @Environment(UserDocumentService.self) private var userDocumentService
    @Environment(AuthService.self) private var authService
    @Environment(BanWarningFacade.self) private var banWarningFacade

    @State private var viewModel: UserProfileViewModel?
    @State private var showUpdateProfile = false
    @State private var selectedWarning: Warning?
    @State private var selectedBan: Ban?

    private var userDocument: UserDocument? { userDocumentService.userDocument }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                profileDetailsCard

                SubscriptionCard(isPlusUser: userDocument?.isPlusUser ?? false)

                warningsSection

                bansSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(AppColors.grey50)
        .navigationTitle(Strings.Profile.profileDetails)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = UserProfileViewModel(banWarningFacade: banWarningFacade)
            }
            await viewModel?.loadWarnings()
            await viewModel?.loadBans()
        }
        .sheet(isPresented: $showUpdateProfile) {
            UpdateProfileSheet()
                .presentationDetents([.large])
        }
        .sheet(item: $selectedWarning) { warning in
            WarningDetailSheet(warning: warning)
                .presentationDetents([.large])
        }
        .sheet(item: $selectedBan) { ban in
            BanDetailSheet(ban: ban)
                .presentationDetents([.large])
        }
    }

    // MARK: - Profile Details Card

    private var profileDetailsCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text(Strings.Profile.profileDetails)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey900)
                Spacer()
                Button {
                    showUpdateProfile = true
                } label: {
                    Text(Strings.Profile.editProfile)
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.primary600)
                }
            }

            avatar

            VStack(spacing: Spacing.sm) {
                ProfileDetailRow(
                    icon: AppIcon.person.systemName,
                    label: Strings.Profile.name,
                    value: userDocument?.displayName ?? ""
                )
                ProfileDetailRow(
                    icon: AppIcon.mail.systemName,
                    label: Strings.Profile.email,
                    value: authService.currentUser?.email ?? userDocument?.email ?? ""
                )
                if let age = computedAge {
                    ProfileDetailRow(
                        icon: AppIcon.calendarBadgeMinus.systemName,
                        label: Strings.Profile.age,
                        value: "\(age) \(Strings.Profile.yearsOld)"
                    )
                }
                if let startDate = userDocument?.userFirstDate {
                    ProfileDetailRow(
                        icon: AppIcon.clock.systemName,
                        label: Strings.Profile.memberSince,
                        value: startDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                ProfileDetailRow(
                    icon: AppIcon.info.systemName,
                    label: Strings.Profile.status,
                    value: userDocumentService.accountStatus.rawValue.capitalized
                )
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

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary50)
                .frame(width: 80, height: 80)

            Image(systemName: AppIcon.person.systemName)
                .font(.system(size: 32))
                .foregroundStyle(AppColors.primary600)
        }
    }

    // MARK: - Warnings

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(Strings.Profile.warnings)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey900)

                if let count = viewModel?.warnings.count, count > 0 {
                    Text("\(count)")
                        .font(Typography.small)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.warning600)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(AppColors.warning50)
                        .clipShape(Capsule())
                }

                Spacer()

                refreshButton { await viewModel?.refreshWarnings() }
            }

            if let warnings = viewModel?.warnings, !warnings.isEmpty {
                ForEach(warnings.prefix(3)) { warning in
                    Button {
                        selectedWarning = warning
                    } label: {
                        WarningItemRow(warning: warning)
                    }
                    .buttonStyle(.plain)
                }
                if warnings.count > 3 {
                    Text("+\(warnings.count - 3) \(Strings.Profile.showMore)")
                        .font(Typography.small)
                        .foregroundStyle(AppColors.primary600)
                }
            } else if viewModel?.isLoadingWarnings == true {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text(Strings.Profile.noWarnings)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
            }
        }
    }

    // MARK: - Bans

    private var bansSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(Strings.Profile.bans)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey900)

                Spacer()

                refreshButton { await viewModel?.refreshBans() }
            }

            if let bans = viewModel?.bans, !bans.isEmpty {
                ForEach(bans.prefix(2)) { ban in
                    Button {
                        selectedBan = ban
                    } label: {
                        BanItemRow(ban: ban)
                    }
                    .buttonStyle(.plain)
                }
            } else if viewModel?.isLoadingBans == true {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text(Strings.Profile.noBans)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
            }
        }
    }

    // MARK: - Helpers

    private func refreshButton(action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: AppIcon.arrowCounterclockwise.systemName)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.primary600)
        }
        .accessibilityLabel(Strings.Profile.refresh)
    }

    private var computedAge: Int? {
        guard let dob = userDocument?.dayOfBirth else { return nil }
        let components = Calendar.current.dateComponents([.year], from: dob, to: Date())
        return components.year
    }
}
