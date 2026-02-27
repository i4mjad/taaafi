import SwiftUI

struct VaultScreen: View {
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(ToastManager.self) private var toastManager
    @Environment(UserDocumentService.self) private var userDocumentService

    @State private var containerVM: VaultContainerViewModel
    @State private var dashboardVM: VaultDashboardViewModel?
    @State private var activitiesVM: ActivitiesViewModel?

    init() {
        _containerVM = State(initialValue: VaultContainerViewModel())
    }

    var body: some View {
        NavigationStack(path: $containerVM.navigationPath) {
            VStack(spacing: 0) {
                XTabBar(
                    tabs: containerVM.visibleTabs,
                    selectedTab: $containerVM.selectedTab,
                    label: { $0.label },
                    icon: { $0.icon },
                    color: { $0.color }
                )

                Divider()

                tabContent
            }
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        PremiumCtaButton(isSubscribed: false)

                        Button {
                            containerVM.showLayoutSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                                .foregroundStyle(AppColors.grey700)
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let config = containerVM.fabConfig {
                    VaultFAB(
                        icon: config.icon,
                        label: config.label,
                        color: config.color,
                        action: { containerVM.handleFABAction() }
                    )
                }
            }
            .sheet(isPresented: $containerVM.showFollowUpSheet) {
                if let dashboardVM {
                    FollowUpSheet(
                        viewModel: FollowUpSheetViewModel(
                            followUpService: FollowUpService(firestoreService: firestoreService),
                            emotionService: EmotionService(firestoreService: firestoreService)
                        ),
                        onSaved: {
                            Task { await dashboardVM.loadData() }
                        }
                    )
                    .presentationDetents([.large])
                }
            }
            .sheet(isPresented: $containerVM.showLayoutSettings) {
                VaultLayoutSettingsSheet(
                    viewModel: VaultLayoutSettingsViewModel(
                        settings: containerVM.layoutSettings,
                        layoutStore: VaultLayoutStore()
                    ),
                    onDismiss: { newSettings in
                        containerVM.layoutSettings = newSettings
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: VaultRoute.self) { route in
                routeDestination(for: route)
            }
            .task {
                initializeViewModels()
                await loadData()
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch containerVM.selectedTab {
        case .vault:
            vaultDashboard
        case .activities:
            activitiesTab
        default:
            placeholderTab
        }
    }

    private var vaultDashboard: some View {
        ScrollView {
            if let vm = dashboardVM {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(containerVM.visibleSections) { section in
                        sectionView(for: section, vm: vm)
                    }
                }
                .padding(.vertical, Spacing.md)
            }
        }
        .refreshable {
            await dashboardVM?.loadData()
        }
    }

    @ViewBuilder
    private func sectionView(for section: VaultSection, vm: VaultDashboardViewModel) -> some View {
        let content = VaultSectionView(
            icon: section.icon,
            iconColor: section.color,
            title: section.label,
            description: String(localized: String.LocalizationValue(section.descriptionKey))
        ) {
            sectionContent(for: section, vm: vm)
        }

        if section.isPremium {
            PremiumBlurOverlay(content: content)
        } else {
            content
                .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private func sectionContent(for section: VaultSection, vm: VaultDashboardViewModel) -> some View {
        switch section {
        case .currentStreaks:
            StreaksView(streaks: vm.streaks)
        case .statistics:
            StatisticsView(statistics: vm.statistics)
        case .calendar:
            VaultCalendarView(
                followUps: vm.calendarFollowUps,
                userFirstDate: vm.streaks.userFirstDate,
                selectedMonth: Binding(
                    get: { vm.calendarMonth },
                    set: { newMonth in
                        vm.calendarMonth = newMonth
                        Task { await vm.loadCalendarMonth(newMonth) }
                    }
                ),
                onDateTap: { date in
                    containerVM.navigate(to: .dayOverview(date: date))
                }
            )
        case .streakAverages:
            StreakAveragesCard(averages: vm.streakAverages)
        case .riskClock:
            RiskClockView(data: vm.riskClockData)
        case .heatMapCalendar:
            HeatMapCalendarView(data: vm.heatMapData)
        case .triggerRadar:
            TriggerRadarView(data: vm.triggerRadarData)
        case .moodCorrelation:
            MoodCorrelationView(data: vm.moodCorrelationData)
        }
    }

    private var activitiesTab: some View {
        ScrollView {
            if let vm = activitiesVM {
                LazyVStack(spacing: Spacing.md) {
                    // Today's Tasks
                    VaultSectionView(
                        icon: "checklist",
                        iconColor: AppColors.primary,
                        title: "\(Strings.Vault.todayTasks) \(vm.completedTasksCount)/\(vm.totalTasksCount)",
                        description: ""
                    ) {
                        if vm.todayTasks.isEmpty {
                            emptyState(
                                icon: "checkmark.circle",
                                message: Strings.Vault.noTasksToday
                            )
                        } else {
                            VStack(spacing: 0) {
                                HStack {
                                    Spacer()
                                    Button(Strings.Vault.showAll) {
                                        containerVM.navigate(to: .allTasks)
                                    }
                                    .font(Typography.caption)
                                    .foregroundStyle(AppColors.primary)
                                }

                                ForEach(vm.todayTasks.prefix(5)) { task in
                                    DayTaskWidget(task: task) {
                                        Task { await vm.toggleTask(task) }
                                    }
                                    if task.id != vm.todayTasks.prefix(5).last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    // Ongoing Activities
                    VaultSectionView(
                        icon: "figure.run",
                        iconColor: AppColors.secondary,
                        title: Strings.Vault.ongoingActivities,
                        description: ""
                    ) {
                        if vm.ongoingActivities.isEmpty {
                            emptyState(
                                icon: "plus.circle",
                                message: Strings.Vault.noOngoingActivities
                            )
                        } else {
                            VStack(spacing: Spacing.xs) {
                                ForEach(vm.ongoingActivities) { activity in
                                    OngoingActivityWidget(activity: activity) {
                                        if let id = activity.id {
                                            containerVM.navigate(to: .ongoingActivity(ongoingActivityId: id))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
            }
        }
        .refreshable {
            await activitiesVM?.loadData()
        }
    }

    private var placeholderTab: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.grey300)

            Text(Strings.Vault.comingSoon)
                .font(Typography.h5)
                .foregroundStyle(AppColors.grey500)

            Text(Strings.Vault.comingSoonMessage)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(AppColors.grey300)
            Text(message)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func routeDestination(for route: VaultRoute) -> some View {
        switch route {
        case .dayOverview(let date):
            DayOverviewScreen(
                date: date,
                followUpService: FollowUpService(firestoreService: firestoreService),
                emotionService: EmotionService(firestoreService: firestoreService)
            )
        case .addActivity:
            AddActivityScreen(
                activityService: ActivityService(firestoreService: firestoreService)
            )
        case .activityOverview(let activityId):
            ActivityOverviewScreen(
                activityId: activityId,
                activityService: ActivityService(firestoreService: firestoreService)
            )
        case .ongoingActivity(let ongoingActivityId):
            OngoingActivityScreen(
                ongoingActivityId: ongoingActivityId,
                activityService: ActivityService(firestoreService: firestoreService)
            )
        case .allTasks:
            AllTasksScreen(
                activityService: ActivityService(firestoreService: firestoreService)
            )
        }
    }

    // MARK: - Initialization

    private func initializeViewModels() {
        let followUpService = FollowUpService(firestoreService: firestoreService)
        let emotionService = EmotionService(firestoreService: firestoreService)
        let activityService = ActivityService(firestoreService: firestoreService)
        let userFirstDate = userDocumentService.userDocument?.userFirstDate ?? Date()

        dashboardVM = VaultDashboardViewModel(
            followUpService: followUpService,
            emotionService: emotionService,
            userFirstDate: userFirstDate
        )
        activitiesVM = ActivitiesViewModel(activityService: activityService)
    }

    private func loadData() async {
        await dashboardVM?.loadData()
        await activitiesVM?.loadData()
    }
}
