import SwiftUI

struct BannedScreen: View {
    let result: SecurityStartupResult
    let banWarningFacade: BanWarningFacade
    let onRefresh: () async -> Void

    @State private var bans: [Ban] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var loadError: String?

    private var isDeviceBan: Bool {
        if case .deviceBanned = result { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                iconSection
                titleSection
                messageSection
                banDetailsSection
                refreshButton
                if isDeviceBan {
                    deviceBanWarning
                }
                appealInfo
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .task {
            await loadBans()
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(AppColors.error100)
                .frame(width: 112, height: 112)

            Image(systemName: isDeviceBan ? "iphone.slash" : "person.crop.circle.badge.xmark")
                .font(.system(size: 48))
                .foregroundStyle(isDeviceBan ? AppColors.error700 : AppColors.error600)
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        Text(isDeviceBan ? Strings.Ban.deviceRestricted : Strings.Ban.accountRestricted)
            .font(Typography.h4)
            .foregroundStyle(AppColors.grey900)
            .multilineTextAlignment(.center)
    }

    // MARK: - Message

    private var messageSection: some View {
        Text(messageText)
            .font(Typography.body)
            .foregroundStyle(AppColors.grey700)
            .multilineTextAlignment(.center)
    }

    private var messageText: String {
        if isDeviceBan {
            return Strings.Ban.devicePermanentlyRestricted
        } else {
            return Strings.Ban.accountRestrictedMessage
        }
    }

    // MARK: - Ban Details

    private var banDetailsSection: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(message: error)
            } else if !bans.isEmpty {
                ForEach(bans) { ban in
                    BanDetailCard(ban: ban)
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView()
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
            .padding(Spacing.xl)
            .background(AppColors.grey50)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.sm))
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(AppColors.warning600)
            Text(Strings.Ban.unableToLoadDetails)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey700)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(AppColors.warning50)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.sm))
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button {
            Task { await refresh() }
        } label: {
            HStack(spacing: Spacing.xs) {
                if isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(Strings.Ban.checkBanStatus)
            }
            .font(Typography.body)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.primary600)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.xs))
        }
        .disabled(isRefreshing)
    }

    // MARK: - Device Ban Warning

    private var deviceBanWarning: some View {
        Text(Strings.Ban.deviceBanNoLogoutMessage)
            .font(Typography.small)
            .foregroundStyle(AppColors.error600)
            .multilineTextAlignment(.center)
    }

    // MARK: - Appeal Info

    private var appealInfo: some View {
        Text(Strings.Ban.appealInfo)
            .font(Typography.caption)
            .foregroundStyle(AppColors.grey500)
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func loadBans() async {
        isLoading = true
        loadError = nil

        let fetchedBans = await banWarningFacade.getCurrentUserBans()
        bans = fetchedBans
        isLoading = false
    }

    private func refresh() async {
        isRefreshing = true
        await loadBans()
        await onRefresh()
        isRefreshing = false
    }
}
