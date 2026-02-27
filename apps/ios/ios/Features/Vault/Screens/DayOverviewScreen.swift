import SwiftUI

struct DayOverviewScreen: View {
    @State private var viewModel: DayOverviewViewModel

    init(date: Date, followUpService: FollowUpService, emotionService: EmotionService) {
        _viewModel = State(initialValue: DayOverviewViewModel(
            date: date,
            followUpService: followUpService,
            emotionService: emotionService
        ))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                followUpsSection
                emotionsSection
            }
            .padding(.vertical, Spacing.md)
        }
        .background(AppColors.background)
        .navigationTitle(Strings.Vault.dayOverview)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Follow-ups Section

    private var followUpsSection: some View {
        VaultSectionView(
            icon: "calendar.badge.clock",
            iconColor: AppColors.primary,
            title: Strings.Vault.followUp,
            description: viewModel.formattedDate
        ) {
            if viewModel.followUps.isEmpty {
                emptyState(message: Strings.Vault.noFollowUps)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(viewModel.followUps) { followUp in
                        followUpRow(followUp)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func followUpRow(_ followUp: FollowUpModel) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(colorForType(followUp.type))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(labelForType(followUp.type))
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey700)

                Text(timeString(followUp.time))
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey500)
            }

            Spacer()

            if !followUp.triggers.isEmpty {
                HStack(spacing: 4) {
                    ForEach(followUp.triggers.prefix(3), id: \.self) { trigger in
                        Text(String(localized: String.LocalizationValue("vault.trigger.\(trigger)")))
                            .font(Typography.bodyTiny)
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.deleteFollowUp(followUp) }
            } label: {
                Label(Strings.Common.cancel, systemImage: "trash")
            }
        }
    }

    // MARK: - Emotions Section

    private var emotionsSection: some View {
        VaultSectionView(
            icon: "heart.fill",
            iconColor: .pink,
            title: Strings.Vault.emotions,
            description: ""
        ) {
            if viewModel.emotions.isEmpty {
                emptyState(message: Strings.Vault.noEmotions)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Spacing.xs) {
                    ForEach(viewModel.emotions) { emotion in
                        VStack(spacing: 2) {
                            Text(emotion.emotionEmoji)
                                .font(.system(size: 28))
                            Text(String(localized: String.LocalizationValue("emotion.\(emotion.emotionName)")))
                                .font(Typography.bodyTiny)
                                .foregroundStyle(AppColors.grey500)
                        }
                        .padding(Spacing.xs)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Helpers

    private func emptyState(message: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(message)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private func colorForType(_ type: FollowUpType) -> Color {
        switch type {
        case .relapse: return AppColors.grey500
        case .pornOnly: return .purple
        case .mastOnly: return .orange
        case .slipUp: return AppColors.error
        case .none: return AppColors.success
        }
    }

    private func labelForType(_ type: FollowUpType) -> String {
        switch type {
        case .relapse: return Strings.Vault.relapse
        case .pornOnly: return Strings.Vault.pornOnly
        case .mastOnly: return Strings.Vault.mastOnly
        case .slipUp: return Strings.Vault.slipUp
        case .none: return Strings.Vault.freeDay
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: date)
    }
}
