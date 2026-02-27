import SwiftUI

struct ActivityOverviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ActivityOverviewViewModel

    init(activityId: String, activityService: ActivityService) {
        _viewModel = State(initialValue: ActivityOverviewViewModel(
            activityId: activityId,
            activityService: activityService
        ))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, Spacing.xxl)
            } else if let activity = viewModel.activity {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    headerSection(activity)
                    tasksSection
                    subscribeButton
                }
                .padding(Spacing.md)
            }
        }
        .background(AppColors.background)
        .navigationTitle(viewModel.activity?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadActivity()
        }
    }

    private func headerSection(_ activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                difficultyBadge(activity.difficulty)
                Spacer()
                Label("\(activity.subscriberCount) \(Strings.Vault.subscribers)", systemImage: "person.2.fill")
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey500)
            }

            Text(activity.description)
                .font(Typography.body)
                .foregroundStyle(AppColors.grey700)
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var tasksSection: some View {
        VaultSectionView(
            icon: "checklist",
            iconColor: AppColors.primary,
            title: Strings.Vault.activityTasks,
            description: ""
        ) {
            VStack(spacing: 0) {
                ForEach(viewModel.tasks) { task in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.grey300)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.name)
                                .font(Typography.body)
                                .foregroundStyle(AppColors.grey700)

                            if !task.description.isEmpty {
                                Text(task.description)
                                    .font(Typography.caption)
                                    .foregroundStyle(AppColors.grey500)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        frequencyBadge(task.frequency)
                    }
                    .padding(.vertical, Spacing.xs)

                    if task.id != viewModel.tasks.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var subscribeButton: some View {
        Button {
            Task { await viewModel.subscribe() }
        } label: {
            Group {
                if viewModel.isSubscribing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(Strings.Vault.subscribe)
                        .font(Typography.body)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isSubscribing)
        .padding(.top, Spacing.sm)
    }

    private func difficultyBadge(_ difficulty: ActivityDifficulty) -> some View {
        let (label, color) = difficultyInfo(difficulty)
        return Text(label)
            .font(Typography.small)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private func difficultyInfo(_ difficulty: ActivityDifficulty) -> (String, Color) {
        switch difficulty {
        case .starter: return (Strings.Vault.starter, AppColors.success)
        case .intermediate: return (Strings.Vault.intermediate, AppColors.warning)
        case .advanced: return (Strings.Vault.advanced, AppColors.error)
        }
    }

    private func frequencyBadge(_ frequency: TaskFrequency) -> some View {
        let label: String = {
            switch frequency {
            case .daily: return Strings.Vault.daily
            case .weekly: return Strings.Vault.weekly
            case .monthly: return Strings.Vault.monthly
            }
        }()

        return Text(label)
            .font(Typography.bodyTiny)
            .foregroundStyle(AppColors.grey500)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(AppColors.grey100)
            .clipShape(Capsule())
    }
}
