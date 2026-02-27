import SwiftUI

struct AllTasksScreen: View {
    @State private var viewModel: AllTasksViewModel

    init(activityService: ActivityService) {
        _viewModel = State(initialValue: AllTasksViewModel(activityService: activityService))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Spacing.xxl)
                } else if viewModel.tasks.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.tasks) { task in
                        DayTaskWidget(task: task) {
                            Task { await viewModel.toggleTask(task) }
                        }
                        .padding(.horizontal, Spacing.md)

                        if task.id != viewModel.tasks.last?.id {
                            Divider()
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .background(AppColors.background)
        .navigationTitle("\(Strings.Vault.allTasks) \(viewModel.completedCount)/\(viewModel.tasks.count)")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadTasks()
        }
        .task {
            await viewModel.loadTasks()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.grey300)
            Text(Strings.Vault.noTasksToday)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}
