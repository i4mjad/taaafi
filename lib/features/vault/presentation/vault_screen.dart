import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
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
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/statistics/statistics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_widget.dart';
import 'package:reboot_app_3/features/vault/data/calendar/calendar_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/data_restoration/data_restoration_button.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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
          ? FloatingActionButton.extended(
              backgroundColor: theme.primary[600],
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
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
            AppLocalizations.of(context).translate('calendar'),
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

        return RefreshIndicator(
          onRefresh: () => _refreshVaultData(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data restoration button (for eligible users)
                const DataRestorationButton(),

                // Horizontal Scrollable Cards
                _buildHorizontalCards(context, theme, orderedCards),
                verticalSpace(Spacing.points16),

                // Render ordered vault elements with consistent spacing
                ..._buildVaultElementsWithSpacing(
                    orderedVaultElements, vaultElementsMap),

                verticalSpace(Spacing.points16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalCards(
      BuildContext context, CustomThemeData theme, List<String> orderedCards) {
    final cardData = {
      'activities': {
        'icon': LucideIcons.clipboardCheck,
        'color': theme.primary[500]!,
        'backgroundColor': theme.primary[50]!,
        'hasPlusBadge': false,
        'route': () => context.goNamed(RouteNames.activities.name),
      },
      'library': {
        'icon': LucideIcons.lamp,
        'color': theme.secondary[500]!,
        'backgroundColor': theme.secondary[50]!,
        'hasPlusBadge': false,
        'route': () => context.goNamed(RouteNames.library.name),
      },
      'diaries': {
        'icon': LucideIcons.pencil,
        'color': theme.tint[500]!,
        'backgroundColor': theme.tint[50]!,
        'hasPlusBadge': false,
        'route': () => context.goNamed(RouteNames.diaries.name),
      },
      'messagingGroups': {
        'icon': LucideIcons.messageSquare,
        'color': theme.warn[500]!,
        'backgroundColor': theme.warn[50]!,
        'hasPlusBadge': true,
        'route': () => context.goNamed(RouteNames.messagingGroups.name),
      },
      'settings': {
        'icon': LucideIcons.settings,
        'color': theme.grey[700]!,
        'backgroundColor': theme.grey[50]!,
        'hasPlusBadge': false,
        'route': () => context.goNamed(RouteNames.vaultSettings.name),
      },
    };

    return SizedBox(
      height: 105, // Height to accommodate uniform cards with badge margin
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        children: orderedCards
            .where((card) =>
                cardData.containsKey(card)) // Filter out cards that don't exist
            .expand((card) => [
                  _buildHorizontalCard(
                    context,
                    theme,
                    cardData[card]!['icon'] as IconData,
                    card,
                    cardData[card]!['color'] as Color,
                    cardData[card]!['backgroundColor'] as Color,
                    cardData[card]!['route'] as VoidCallback,
                    hasPlusBadge:
                        cardData[card]!['hasPlusBadge'] as bool? ?? false,
                  ),
                  if (card !=
                      orderedCards.where((c) => cardData.containsKey(c)).last)
                    horizontalSpace(
                        Spacing.points4), // Reduced spacing between cards
                ])
            .toList(),
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    CustomThemeData theme,
    IconData icon,
    String textKey,
    Color iconColor,
    Color backgroundColor,
    VoidCallback onTap, {
    bool hasPlusBadge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: EdgeInsets.all(4), // Add margin to accommodate badge
        child: Stack(
          clipBehavior: Clip.none, // Allow badge to overflow slightly
          children: [
            WidgetsContainer(
              width: 90, // Fixed width for all cards based on longest content
              height: 85, // Fixed height for consistency
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              backgroundColor: backgroundColor,
              borderSide:
                  BorderSide(color: iconColor.withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container with fixed size
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  // Fixed spacing
                  SizedBox(height: 6),
                  // Text with consistent width
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context).translate(textKey),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Plus badge overlay - positioned within visible area
            if (hasPlusBadge)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding:
                      EdgeInsets.all(5), // Increased padding for larger badge
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEBA01),
                    borderRadius:
                        BorderRadius.circular(8), // Larger border radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Ta3afiPlatformIcons.plus,
                    color: Colors.black,
                    size: 12, // Larger icon size
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
        result.add(verticalSpace(Spacing.points4)); // Consistent 24px spacing
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          verticalSpace(Spacing.points8),
          Text(
            description,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
          verticalSpace(Spacing.points20),

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          verticalSpace(Spacing.points8),
          Text(
            description,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
          verticalSpace(Spacing.points20),

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
