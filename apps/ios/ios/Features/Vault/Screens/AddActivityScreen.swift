import SwiftUI

struct AddActivityScreen: View {
    @State private var viewModel: AddActivityViewModel

    init(activityService: ActivityService) {
        _viewModel = State(initialValue: AddActivityViewModel(activityService: activityService))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Spacing.xxl)
                } else if viewModel.filteredActivities.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.filteredActivities) { activity in
                        NavigationLink(value: VaultRoute.activityOverview(activityId: activity.id ?? "")) {
                            activityCard(activity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(AppColors.background)
        .navigationTitle(Strings.Vault.addActivity)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: Strings.Vault.searchActivities)
        .task {
            await viewModel.loadActivities()
        }
    }

    private func activityCard(_ activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(activity.name)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey700)

                Spacer()

                difficultyBadge(activity.difficulty)
            }

            Text(activity.description)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
                .lineLimit(2)

            HStack(spacing: Spacing.md) {
                Label("\(activity.subscriberCount)", systemImage: "person.2.fill")
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey500)

                if let taskCount = activity.tasks?.count {
                    Label("\(taskCount) \(Strings.Vault.activityTasks)", systemImage: "checklist")
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func difficultyBadge(_ difficulty: ActivityDifficulty) -> some View {
        let (label, color) = difficultyInfo(difficulty)
        return Text(label)
            .font(Typography.bodyTiny)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
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

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.grey300)
            Text(Strings.Vault.noOngoingActivities)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}
