import SwiftUI

struct OngoingActivityScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OngoingActivityViewModel
    @State private var showUnsubscribeAlert = false

    init(ongoingActivityId: String, activityService: ActivityService) {
        _viewModel = State(initialValue: OngoingActivityViewModel(
            ongoingActivityId: ongoingActivityId,
            activityService: activityService
        ))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, Spacing.xxl)
            } else {
                VStack(spacing: Spacing.md) {
                    progressHeader
                    tasksSection
                    unsubscribeButton
                }
                .padding(Spacing.md)
            }
        }
        .background(AppColors.background)
        .navigationTitle(viewModel.activity?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .alert(Strings.Vault.unsubscribe, isPresented: $showUnsubscribeAlert) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Vault.unsubscribe, role: .destructive) {
                Task {
                    await viewModel.unsubscribe()
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    private var progressHeader: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(AppColors.grey200, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.progress)

                VStack(spacing: 2) {
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(Typography.h3)
                        .foregroundStyle(AppColors.primary)
                    Text(Strings.Vault.progress)
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                }
            }
            .frame(width: 100, height: 100)

            if let activity = viewModel.ongoingActivity {
                Text("\(Strings.Vault.startDate): \(formattedDate(activity.startDate))")
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey500)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
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
                    DayTaskWidget(task: task) {
                        Task { await viewModel.toggleTask(task) }
                    }
                    if task.id != viewModel.tasks.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var unsubscribeButton: some View {
        Button {
            showUnsubscribeAlert = true
        } label: {
            Text(Strings.Vault.unsubscribe)
                .font(Typography.body)
                .foregroundStyle(AppColors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: date)
    }
}
