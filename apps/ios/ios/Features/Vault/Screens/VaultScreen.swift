import SwiftUI

struct VaultScreen: View {
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(ToastManager.self) private var toastManager
    @Environment(UserDocumentService.self) private var userDocumentService

    @State private var containerVM: VaultContainerViewModel
    @State private var dashboardVM: VaultDashboardViewModel?
    @State private var activitiesVM: ActivitiesViewModel?
    @State private var tabBarHeight: CGFloat = 50

    // Sheet states
    @State private var streakDisplaySettings: StreakDisplaySettings = StreakSettingsStore().load()
    @State private var showStreakSettings = false
    @State private var showResetData = false
    @State private var streakPeriodsType: FollowUpType?
    @State private var helpSection: VaultSection?
    @State private var showSmartAlerts = false
    @State private var showDataRestoration = false
    @State private var showDataErrorReport = false
    @State private var showVaultInfo = false

    init() {
        _containerVM = State(initialValue: VaultContainerViewModel())
    }

    var body: some View {
        NavigationStack(path: $containerVM.navigationPath) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        tabContent
                    }
                    .padding(.top, tabBarHeight)
                    .id("vaultScrollTop")
                }
                .onChange(of: containerVM.selectedTab) {
                    withAnimation {
                        scrollProxy.scrollTo("vaultScrollTop", anchor: .top)
                    }
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    XTabBar(
                        tabs: containerVM.visibleTabs,
                        selectedTab: $containerVM.selectedTab,
                        label: { $0.label },
                        icon: { $0.icon },
                        color: { $0.color }
                    )
                    Divider()
                }
                .glassBackground()
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: TabBarHeightKey.self,
                            value: proxy.size.height
                        )
                    }
                }
            }
            .onPreferenceChange(TabBarHeightKey.self) { tabBarHeight = $0 }
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.title)
            .navigationBarTitleDisplayMode(.inline)
            .hideNavBarGlassForUnifiedHeader()
            .refreshable {
                switch containerVM.selectedTab {
                case .vault: await dashboardVM?.loadData()
                case .activities: await activitiesVM?.loadData()
                default: break
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showVaultInfo = true
                    } label: {
                        Image(AppIcon.plusIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(Color(red: 254/255, green: 186/255, blue: 1/255))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        containerVM.showLayoutSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.grey700)
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
            // Follow-up sheet
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
            // Layout settings sheet
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
            // Streak settings sheet
            .sheet(isPresented: $showStreakSettings) {
                if let dashboardVM {
                    StreakSettingsSheet(
                        viewModel: StreakSettingsViewModel(
                            userFirstDate: dashboardVM.streaks.userFirstDate
                        ),
                        onSave: { newSettings in
                            streakDisplaySettings = newSettings
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            // Reset data sheet
            .sheet(isPresented: $showResetData) {
                ResetDataSheet()
            }
            // Streak periods sheet
            .sheet(item: $streakPeriodsType) { type in
                if let dashboardVM {
                    StreakPeriodsSheet(
                        viewModel: StreakPeriodsViewModel(
                            followUpType: type,
                            followUpService: FollowUpService(firestoreService: firestoreService),
                            userFirstDate: dashboardVM.streaks.userFirstDate
                        )
                    )
                    .presentationDetents([.large])
                }
            }
            // Help sheet
            .sheet(item: $helpSection) { section in
                HelpSheet(data: VaultHelpContent.content(for: section))
                    .presentationDetents([.medium, .large])
            }
            // Smart alerts sheet
            .sheet(isPresented: $showSmartAlerts) {
                SmartAlertsSheet(
                    viewModel: SmartAlertsViewModel(
                        smartAlertService: SmartAlertService(firestoreService: firestoreService),
                        followUpService: FollowUpService(firestoreService: firestoreService),
                        userFirstDate: dashboardVM?.streaks.userFirstDate ?? Date()
                    )
                )
                .presentationDetents([.medium, .large])
            }
            // Data restoration sheet
            .sheet(isPresented: $showDataRestoration) {
                DataRestorationSheet(
                    viewModel: DataRestorationViewModel(userDocumentService: userDocumentService)
                )
                .presentationDetents([.medium])
            }
            // Data error report sheet
            .sheet(isPresented: $showDataErrorReport) {
                DataErrorReportSheet(
                    viewModel: DataErrorReportViewModel(firestoreService: firestoreService)
                )
                .presentationDetents([.medium, .large])
            }
            // Vault info sheet
            .sheet(isPresented: $showVaultInfo) {
                VaultInfoSheet()
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
        Group {
            if let vm = dashboardVM {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(containerVM.visibleSections) { section in
                        sectionView(for: section, vm: vm)
                    }
                }
                .padding(.vertical, Spacing.md)
            }
        }
    }

    private let goldColor = Color(red: 254/255, green: 186/255, blue: 1/255)

    @ViewBuilder
    private func sectionView(for section: VaultSection, vm: VaultDashboardViewModel) -> some View {
        let description = String(localized: String.LocalizationValue(section.descriptionKey))

        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header row
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(section.color)

                Text(section.label)
                    .font(Typography.h5)
                    .foregroundStyle(section.isPremium ? goldColor : AppColors.grey700)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    helpSection = section
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.grey600)
                        .padding(6)
                        .background(AppColors.grey100)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            if !description.isEmpty {
                Text(description)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey600)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            if section.isPremium {
                PremiumBlurOverlay {
                    sectionContent(for: section, vm: vm)
                }
            } else {
                sectionContent(for: section, vm: vm)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private func sectionContent(for section: VaultSection, vm: VaultDashboardViewModel) -> some View {
        switch section {
        case .currentStreaks:
            StreaksView(
                streaks: vm.streaks,
                settings: streakDisplaySettings,
                onStreakTap: { type in
                    streakPeriodsType = type
                },
                onCustomizeTap: {
                    showStreakSettings = true
                },
                onResetTap: {
                    showResetData = true
                }
            )
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
            VStack(spacing: Spacing.xs) {
                RiskClockView(data: vm.riskClockData)
                Button {
                    showSmartAlerts = true
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 12))
                        Text(Strings.Vault.smartAlertsTitle)
                            .font(Typography.small)
                    }
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(AppColors.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        case .heatMapCalendar:
            HeatMapCalendarView(data: vm.heatMapData)
        case .triggerRadar:
            TriggerRadarView(data: vm.triggerRadarData)
        case .moodCorrelation:
            MoodCorrelationView(data: vm.moodCorrelationData)
        }
    }

    private var activitiesTab: some View {
        Group {
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
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

// MARK: - FollowUpType Identifiable Conformance

extension FollowUpType: Identifiable {
    public var id: String { rawValue }
}

// MARK: - iOS 26 Liquid Glass

private extension View {
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.background {
                Color.clear
                    .glassEffect(.regular, in: Rectangle())
                    .ignoresSafeArea(.container, edges: .top)
            }
        } else {
            self.background(AppColors.background)
        }
    }

    @ViewBuilder
    func hideNavBarGlassForUnifiedHeader() -> some View {
        if #available(iOS 26.0, *) {
            self.toolbarBackground(.hidden, for: .navigationBar)
        } else {
            self
        }
    }
}

private struct TabBarHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
