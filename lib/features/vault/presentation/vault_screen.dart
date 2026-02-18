import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_cta_button.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/streaks/current_streaks_section.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_section.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/calendar/calendar_section.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/follow_up/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/shorebird_update_widget.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_layout_provider.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/vault_layout_settings_sheet.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_blur_overlay.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/heat_map_calendar.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/streak_averages_card.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/trigger_radar.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/risk_clock.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/mood_correlation_chart.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/help/help_bottom_sheet.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/statistics/statistics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_widget.dart';
import 'package:reboot_app_3/features/vault/data/calendar/calendar_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/data_restoration/data_restoration_button.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activities_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/library_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/diaries/diaries_screen.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_notifier.dart';
import 'package:reboot_app_3/features/messaging/providers/messaging_groups_providers.dart';
import 'package:reboot_app_3/features/messaging/presentation/messaging_groups_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/vault_settings_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> _visibleCards = [];

  @override
  void initState() {
    super.initState();
    // Initialize will happen in build after we have the vault layout settings
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initializeTabController(List<String> visibleCards) {
    if (visibleCards.length != _visibleCards.length ||
        !_listEquals(visibleCards, _visibleCards)) {
      _visibleCards = List.from(visibleCards);
      _tabController?.dispose();
      _tabController = TabController(
        length: visibleCards.length + 1, // +1 for the vault tab
        vsync: this,
      );
      _tabController!.addListener(() {
        setState(() {});
      });
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _refreshVaultData(WidgetRef ref) async {
    // Refresh core data providers
    ref.invalidate(statisticsNotifierProvider);
    ref.invalidate(streakNotifierProvider);
    ref.invalidate(followUpNotifierProvider);
    ref.invalidate(calendarNotifierProvider);
    ref.invalidate(calendarStreamProvider);

    // Refresh analytics providers for premium features
    ref.invalidate(heatMapDataProvider);
    ref.invalidate(triggerRadarDataProvider);
    ref.invalidate(riskClockDataProvider);
    ref.invalidate(streakAveragesProvider);
    ref.invalidate(moodCorrelationDataProvider);
    ref.invalidate(cachedMoodCorrelationDataProvider);
    ref.invalidate(premiumAnalyticsServiceProvider);

    // Refresh follow-up related providers
    ref.invalidate(followUpsProvider);
    ref.invalidate(detailedStreakProvider);

    // Wait for the main providers to refresh
    await Future.wait([
      ref.refresh(statisticsNotifierProvider.future),
      ref.refresh(streakNotifierProvider.future),
      ref.refresh(followUpNotifierProvider.future),
      ref.refresh(calendarNotifierProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final themeController = ref.watch(customThemeProvider);
    final accountStatus = ref.watch(accountStatusProvider);
    final shorebirdUpdateState = ref.watch(shorebirdUpdateProvider);
    final showMainContent = accountStatus == AccountStatus.ok;
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);

    // Check if Shorebird update requires blocking the entire screen
    final shouldBlockForShorebird =
        _shouldBlockForShorebirdUpdate(shorebirdUpdateState.status);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'vault',
        false,
        false,
        actions: showMainContent
            ? [
                PremiumCtaAppBarIcon(),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      builder: (context) => const VaultLayoutSettingsSheet(),
                    );
                  },
                  icon: Icon(LucideIcons.settings),
                ),
                // horizontalSpace(Spacing.points16),
              ]
            : null,
      ),
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          // Priority 1: Check if Shorebird update requires blocking (highest priority)
          if (shouldBlockForShorebird) {
            return const ShorebirdUpdateBlockingWidget();
          }

          // Priority 2: Check account status
          switch (accountStatus) {
            case AccountStatus.loading:
              return Center(child: Spinner());
            case AccountStatus.needCompleteRegistration:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CompleteRegistrationBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needConfirmDetails:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmDetailsBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needEmailVerification:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmEmailBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.pendingDeletion:
            case AccountStatus.error:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AccountActionBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.ok:
              return _buildMainContent(context, theme, themeController);
          }
        },
      ),
      floatingActionButton: showMainContent && !shouldBlockForShorebird
          ? AnimatedBuilder(
              animation: _tabController ?? const AlwaysStoppedAnimation(0),
              builder: (context, child) {
                return _buildFloatingActionButton(context, theme) ??
                    const SizedBox.shrink();
              },
            )
          : null,
    );
  }

  Widget _buildMainContent(
      BuildContext context, CustomThemeData theme, dynamic themeController) {
    return Consumer(
      builder: (context, ref, child) {
        final vaultLayoutSettings = ref.watch(vaultLayoutProvider);

        final orderedVaultElements =
            vaultLayoutSettings.getOrderedVisibleVaultElements();
        final orderedCards = vaultLayoutSettings.getOrderedVisibleCards();

        final hasSubscription = ref.watch(hasActiveSubscriptionProvider);
        final isDarkTheme = themeController.darkTheme;

        // Initialize tab controller with visible cards (vault will be added separately)
        _initializeTabController(orderedCards);
        final allTabs = ['vault', ...orderedCards];

        if (_tabController == null || allTabs.isEmpty) {
          return const Center(child: Spinner());
        }

        final cardData = _getCardData(context, theme);

        final vaultElementsMap = <String, Widget>{
          'currentStreaks': _buildVaultElement(
            context,
            theme,
            AppLocalizations.of(context).translate('current-streaks'),
            AppLocalizations.of(context)
                .translate('current-streaks-description'),
            const CurrentStreaksSection(),
            LucideIcons.zap,
            const Color(0xFF6366F1), // Indigo
            'currentStreaks',
          ),
          'streakAverages': _buildAnalyticsFeature(
            context,
            theme,
            hasSubscription,
            AppLocalizations.of(context).translate('streak-averages-title'),
            AppLocalizations.of(context).translate('streak-averages-desc'),
            const StreakAveragesCard(),
            LucideIcons.trendingUp,
            const Color(0xFF22C55E),
            isDarkTheme,
            'streakAverages',
          ),
          'statistics': _buildVaultElement(
            context,
            theme,
            AppLocalizations.of(context).translate('statistics'),
            AppLocalizations.of(context).translate('statistics-description'),
            const StatisticsSection(),
            LucideIcons.pieChart,
            const Color(0xFF8B5CF6), // Purple
            'statistics',
          ),
          'riskClock': _buildAnalyticsFeature(
            context,
            theme,
            hasSubscription,
            AppLocalizations.of(context).translate('risk-clock-title'),
            AppLocalizations.of(context).translate('risk-clock-desc'),
            const RiskClock(),
            LucideIcons.clock,
            const Color(0xFF06B6D4),
            isDarkTheme,
            'riskClock',
          ),
          'calendar': _buildVaultElement(
            context,
            theme,
            AppLocalizations.of(context).translate('reboot-calender'),
            AppLocalizations.of(context).translate('calendar-description'),
            const CalendarSection(),
            LucideIcons.calendar,
            const Color(0xFF06B6D4), // Cyan
            'calendar',
          ),
          'heatMapCalendar': _buildAnalyticsFeature(
            context,
            theme,
            hasSubscription,
            AppLocalizations.of(context).translate('heat-map-calendar-title'),
            AppLocalizations.of(context).translate('day-of-month-desc'),
            const HeatMapCalendar(),
            LucideIcons.calendar,
            const Color(0xFFEF4444),
            isDarkTheme,
            'heatMapCalendar',
          ),
          'triggerRadar': _buildAnalyticsFeature(
            context,
            theme,
            hasSubscription,
            AppLocalizations.of(context).translate('trigger-radar-title'),
            AppLocalizations.of(context).translate('trigger-radar-desc'),
            const TriggerRadar(),
            LucideIcons.radar,
            const Color(0xFFF97316),
            isDarkTheme,
            'triggerRadar',
          ),
          'moodCorrelation': _buildAnalyticsFeature(
            context,
            theme,
            hasSubscription,
            AppLocalizations.of(context).translate('mood-correlation-title'),
            AppLocalizations.of(context)
                .translate('mood-relapse-correlation-desc'),
            const MoodCorrelationChart(),
            LucideIcons.heartHandshake,
            const Color(0xFFEC4899),
            isDarkTheme,
            'moodCorrelation',
          ),
        };

        return Column(
          children: [
            // Tab bar with animated indicator
            AnimatedBuilder(
              animation: _tabController!,
              builder: (context, child) {
                return TabBar(
                  controller: _tabController!,
                  indicatorColor: _getActiveTabColor(theme, allTabs, cardData),
                  labelColor: theme.primary[600],
                  unselectedLabelColor: theme.grey[600],
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: allTabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tab = entry.value;

                    if (tab == 'vault') {
                      return Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.lock,
                              size: 18,
                              color: _tabController!.index == index
                                  ? theme.primary[600]
                                  : theme.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).translate('vault'),
                              style: (_tabController!.index == index
                                      ? TextStyles.footnoteSelected
                                      : TextStyles.footnote)
                                  .copyWith(
                                color: _tabController!.index == index
                                    ? theme.primary[600]
                                    : theme.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final card = cardData[tab];
                    if (card == null)
                      return const Tab(child: SizedBox.shrink());

                    // Get card color based on the card type
                    final Color cardColor = card['color'] as Color;

                    return Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            card['icon'] as IconData,
                            size: 18,
                            color: _tabController!.index == index
                                ? cardColor
                                : theme.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)
                                .translate(card['translationKey'] as String),
                            style: (_tabController!.index == index
                                    ? TextStyles.footnoteSelected
                                    : TextStyles.footnote)
                                .copyWith(
                              color: _tabController!.index == index
                                  ? cardColor
                                  : theme.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Tab bar view
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: allTabs.map((tab) {
                  if (tab == 'vault') {
                    return _buildVaultContent(
                      context,
                      theme,
                      ref,
                      orderedVaultElements,
                      vaultElementsMap,
                    );
                  }

                  final card = cardData[tab];
                  if (card == null) return const SizedBox.shrink();

                  return _buildCardContent(
                    context,
                    theme,
                    tab,
                    card,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVaultContent(
    BuildContext context,
    CustomThemeData theme,
    WidgetRef ref,
    List<String> orderedVaultElements,
    Map<String, Widget> vaultElementsMap,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refreshVaultData(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data restoration button (for eligible users)
            const DataRestorationButton(),

            verticalSpace(Spacing.points16),

            // Render ordered vault elements with consistent spacing
            ..._buildVaultElementsWithSpacing(
                orderedVaultElements, vaultElementsMap),

            verticalSpace(Spacing.points16),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    CustomThemeData theme,
    String cardKey,
    Map<String, dynamic> cardData,
  ) {
    // Use the ACTUAL original screen components
    switch (cardKey) {
      case 'activities':
        return const ActivitiesScreen();
      case 'library':
        return const LibraryScreen();
      case 'diaries':
        return const DiariesScreen();
      case 'messagingGroups':
        return const MessagingGroupsScreen();
      case 'settings':
        return const VaultSettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getActiveTabColor(CustomThemeData theme, List<String> allTabs,
      Map<String, Map<String, dynamic>> cardData) {
    if (_tabController == null) return theme.primary[600]!;

    final currentIndex = _tabController!.index;
    if (currentIndex >= allTabs.length) return theme.primary[600]!;

    final currentTab = allTabs[currentIndex];

    if (currentTab == 'vault') {
      return theme.primary[600]!;
    }

    final card = cardData[currentTab];
    if (card == null) return theme.primary[600]!;

    return card['color'] as Color? ?? theme.primary[600]!;
  }

  Widget? _buildFloatingActionButton(
      BuildContext context, CustomThemeData theme) {
    if (_tabController == null) return null;

    final currentIndex = _tabController!.index;
    final allTabs = ['vault', ..._visibleCards];

    if (currentIndex >= allTabs.length) return null;

    final currentTab = allTabs[currentIndex];
    final cardData = _getCardData(context, theme);

    switch (currentTab) {
      case 'vault':
        // Daily follow-up FAB
        return FloatingActionButton.extended(
          backgroundColor: theme.primary[600],
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (BuildContext context) {
                return FollowUpSheet(DateTime.now());
              },
            );
          },
          label: Text(
            AppLocalizations.of(context).translate("daily-follow-up"),
            style: TextStyles.caption.copyWith(color: theme.grey[50]),
          ),
          icon: Icon(LucideIcons.pencil, color: theme.grey[50]),
        );

      case 'activities':
        // Add activity FAB with matching color
        final activitiesColor =
            cardData['activities']?['color'] as Color? ?? theme.primary[600]!;
        return FloatingActionButton.extended(
          backgroundColor: activitiesColor,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.goNamed(RouteNames.addActivity.name);
          },
          label: Text(
            AppLocalizations.of(context).translate("add-activity"),
            style: TextStyles.caption.copyWith(color: theme.grey[50]),
          ),
          icon: Icon(LucideIcons.plus, color: theme.grey[50]),
        );

      case 'diaries':
        // Add diary FAB with matching color
        final diariesColor =
            cardData['diaries']?['color'] as Color? ?? theme.tint[500]!;
        return FloatingActionButton.extended(
          backgroundColor: diariesColor,
          onPressed: () async {
            try {
              HapticFeedback.lightImpact();
              final diaryId = await ref
                  .read(diariesNotifierProvider.notifier)
                  .createEmptyDiary();
              if (context.mounted) {
                context.goNamed(RouteNames.diary.name,
                    pathParameters: {'id': diaryId});
              }
            } catch (e) {
              // Handle error silently
            }
          },
          label: Text(
            AppLocalizations.of(context).translate("new-diary"),
            style: TextStyles.caption.copyWith(color: theme.grey[50]),
          ),
          icon: Icon(LucideIcons.plus, color: theme.grey[50]),
        );

      case 'messagingGroups':
        // Refresh FAB with matching color
        final messagingColor =
            cardData['messagingGroups']?['color'] as Color? ?? theme.warn[500]!;
        return FloatingActionButton(
          backgroundColor: messagingColor,
          onPressed: () async {
            try {
              HapticFeedback.lightImpact();
              await ref
                  .read(messagingGroupsNotifierProvider.notifier)
                  .refresh();
            } catch (e) {
              // Silently handle refresh errors
            }
          },
          child: Icon(LucideIcons.refreshCw, color: theme.grey[50]),
        );

      case 'library':
      case 'settings':
      default:
        // No FAB for library and settings
        return null;
    }
  }

  Map<String, Map<String, dynamic>> _getCardData(
      BuildContext context, CustomThemeData theme) {
    return {
      'activities': {
        'icon': LucideIcons.clipboardCheck,
        'color': theme.primary[500]!,
        'backgroundColor': theme.primary[50]!,
        'translationKey': 'activities',
        'route': () => context.goNamed(RouteNames.activities.name),
      },
      'library': {
        'icon': LucideIcons.lamp,
        'color': theme.secondary[500]!,
        'backgroundColor': theme.secondary[50]!,
        'translationKey': 'library',
        'route': () => context.goNamed(RouteNames.library.name),
      },
      'diaries': {
        'icon': LucideIcons.pencil,
        'color': theme.tint[500]!,
        'backgroundColor': theme.tint[50]!,
        'translationKey': 'diaries',
        'route': () => context.goNamed(RouteNames.diaries.name),
      },
      'messagingGroups': {
        'icon': LucideIcons.messageSquare,
        'color': theme.warn[500]!,
        'backgroundColor': theme.warn[50]!,
        'translationKey': 'messagingGroups',
        'route': () => context.goNamed(RouteNames.messagingGroups.name),
      },
      'settings': {
        'icon': LucideIcons.settings,
        'color': theme.grey[700]!,
        'backgroundColor': theme.grey[50]!,
        'translationKey': 'vault-settings',
        'route': () => context.goNamed(RouteNames.vaultSettings.name),
      },
    };
  }

  List<Widget> _buildVaultElementsWithSpacing(
      List<String> orderedElements, Map<String, Widget> elementsMap) {
    final List<Widget> result = [];

    // Filter out null elements and get visible widgets
    final visibleElements = orderedElements
        .where((element) => elementsMap[element] != null)
        .map((element) => elementsMap[element]!)
        .toList();

    // Add spacing between visible elements only
    for (int i = 0; i < visibleElements.length; i++) {
      result.add(visibleElements[i]);

      // Add spacing after each element except the last one
      if (i < visibleElements.length - 1) {
        result.add(
            verticalSpace(Spacing.points16)); // 16px spacing between sections
      }
    }

    return result;
  }

  Widget _buildVaultElement(
    BuildContext context,
    CustomThemeData theme,
    String title,
    String description,
    Widget content,
    IconData icon,
    Color iconColor,
    String sectionKey,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Icon (always visible)
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.h5.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Help button
              GestureDetector(
                onTap: () => _showHelpForSection(context, sectionKey),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.helpCircle,
                    size: 16,
                    color: theme.grey[600],
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points4),
          Text(
            description,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
              height: 1.35,
            ),
          ),
          verticalSpace(Spacing.points8),

          // Content (no blur for free features)
          content,
        ],
      ),
    );
  }

  Widget _buildAnalyticsFeature(
    BuildContext context,
    CustomThemeData theme,
    bool hasSubscription,
    String title,
    String description,
    Widget content,
    IconData icon,
    Color iconColor,
    bool isDarkTheme,
    String sectionKey,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Icon (always visible) - Consistent help button for all features
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.h5.copyWith(
                    color: const Color(0xFFFEBA01),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Help button - consistent for all features
              GestureDetector(
                onTap: () => _showHelpForSection(context, sectionKey),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.helpCircle,
                    size: 16,
                    color: theme.grey[600],
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points4),
          Text(
            description,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
              height: 1.35,
            ),
          ),
          verticalSpace(Spacing.points8),

          // Content with conditional blur
          if (hasSubscription)
            content
          else
            PremiumBlurOverlay(
              content: content,
              isDarkTheme: isDarkTheme,
              constraints: const BoxConstraints(
                minHeight: 120,
                maxHeight: 280,
              ),
              margin: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  void _showHelpForSection(BuildContext context, String sectionKey) {
    switch (sectionKey) {
      case 'currentStreaks':
        VaultHelpSheets.showCurrentStreaksHelp(context);
        break;
      case 'statistics':
        VaultHelpSheets.showStatisticsHelp(context);
        break;
      case 'calendar':
        VaultHelpSheets.showCalendarHelp(context);
        break;
      case 'heatMapCalendar':
        VaultHelpSheets.showHeatMapCalendarHelp(context);
        break;
      case 'triggerRadar':
        VaultHelpSheets.showTriggerRadarHelp(context);
        break;
      case 'riskClock':
        VaultHelpSheets.showRiskClockHelp(context);
        break;
      case 'moodCorrelation':
        VaultHelpSheets.showMoodCorrelationHelp(context);
        break;
      case 'streakAverages':
        VaultHelpSheets.showStreakAveragesHelp(context);
        break;
      default:
        VaultHelpSheets.showPremiumFeatureHelp(context, sectionKey);
        break;
    }
  }

  /// Determines if Shorebird update status should block the entire screen
  bool _shouldBlockForShorebirdUpdate(AppUpdateStatus status) {
    return status == AppUpdateStatus.available ||
        status == AppUpdateStatus.downloading ||
        status == AppUpdateStatus.completed;
  }
}
