import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
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
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/heat_map_calendar.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/streak_averages_card.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/trigger_radar.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/risk_clock.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/analytics/mood_correlation_chart.dart';
import 'dart:ui';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final showMainContent = accountStatus == AccountStatus.ok;
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
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
                )
              ]
            : null,
      ),
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
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
            case AccountStatus.ok:
              return _buildMainContent(context, theme);
          }
        },
      ),
      floatingActionButton: showMainContent
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

  Widget _buildMainContent(BuildContext context, CustomThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final vaultLayoutSettings = ref.watch(vaultLayoutProvider);

        final orderedVaultElements =
            vaultLayoutSettings.getOrderedVisibleVaultElements();
        final orderedCards = vaultLayoutSettings.getOrderedVisibleCards();

        final vaultElementsMap = <String, Widget>{
          'currentStreaks': const CurrentStreaksSection(),
          'statistics': const StatisticsSection(),
          'calendar': const CalendarSection(),
        };

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shorebird update widget
              const ShorebirdUpdateWidget(),
              verticalSpace(Spacing.points16),

              // Horizontal Scrollable Cards
              _buildHorizontalCards(context, theme, orderedCards),
              verticalSpace(Spacing.points16),

              // Premium Analytics CTA
              _buildPremiumAnalyticsCTA(context, theme),

              // Render ordered vault elements
              ...orderedVaultElements
                  .expand((element) => [
                        vaultElementsMap[element] ?? SizedBox.shrink(),
                        verticalSpace(Spacing.points16),
                      ])
                  .toList()
                ..removeLast(), // Remove the last spacing

              verticalSpace(Spacing.points16),

              // Analytics Section
              _buildAnalyticsSection(context, theme),
              verticalSpace(Spacing.points16),
            ],
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
        'route': () => context.goNamed(RouteNames.activities.name),
      },
      'library': {
        'icon': LucideIcons.lamp,
        'color': theme.secondary[500]!,
        'backgroundColor': theme.secondary[50]!,
        'route': () => context.goNamed(RouteNames.library.name),
      },
      'diaries': {
        'icon': LucideIcons.pencil,
        'color': theme.tint[500]!,
        'backgroundColor': theme.tint[50]!,
        'route': () => context.goNamed(RouteNames.diaries.name),
      },
      'notifications': {
        'icon': LucideIcons.bell,
        'color': theme.warn[500]!,
        'backgroundColor': theme.warn[50]!,
        'route': () => context.goNamed(RouteNames.notifications.name),
      },
      'settings': {
        'icon': LucideIcons.settings,
        'color': theme.grey[500]!,
        'backgroundColor': theme.grey[50]!,
        'route': () => context.goNamed(RouteNames.vaultSettings.name),
      },
    };

    return SizedBox(
      height: 80,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        children: orderedCards
            .expand((card) => [
                  _buildHorizontalCard(
                    context,
                    theme,
                    cardData[card]!['icon'] as IconData,
                    card,
                    cardData[card]!['color'] as Color,
                    cardData[card]!['backgroundColor'] as Color,
                    cardData[card]!['route'] as VoidCallback,
                  ),
                  if (card != orderedCards.last)
                    horizontalSpace(Spacing.points8),
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
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: WidgetsContainer(
        width: 70,
        height: 70,
        padding: EdgeInsets.all(8),
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
          children: [
            Container(
              padding: EdgeInsets.all(6),
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
            verticalSpace(Spacing.points4),
            Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumAnalyticsCTA(
      BuildContext context, CustomThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();

                  if (hasSubscription) {
                    // Navigate to premium analytics
                    context.goNamed(RouteNames.premiumAnalytics.name);
                  } else {
                    // Show subscription modal
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (context) =>
                          const TaaafiPlusSubscriptionScreen(),
                    );
                  }
                },
                child: WidgetsContainer(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  backgroundColor: theme.primary[50],
                  borderSide: BorderSide(color: theme.primary[200]!, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary[100]!.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primary[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.barChart3,
                          color: theme.primary[600],
                          size: 24,
                        ),
                      ),
                      horizontalSpace(Spacing.points16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate('premium-analytics-title'),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            verticalSpace(Spacing.points4),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('premium-analytics-subtitle'),
                              style: TextStyles.small.copyWith(
                                color: theme.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        color: theme.primary[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // TODO: Remove this test button in production
              if (true) // Change to false to hide test button
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () async {
                      // Toggle subscription status for testing
                      Future(() async {
                        final notifier =
                            ref.read(subscriptionNotifierProvider.notifier);
                        final currentStatus =
                            ref.read(subscriptionNotifierProvider).valueOrNull;

                        if (currentStatus?.status == SubscriptionStatus.plus &&
                            currentStatus?.isActive == true) {
                          // Switch to free
                          await notifier.updateSubscriptionForTesting(
                            const SubscriptionInfo(
                              status: SubscriptionStatus.free,
                              isActive: false,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Test: Switched to FREE')),
                          );
                        } else {
                          // Switch to plus
                          await notifier.updateSubscriptionForTesting(
                            SubscriptionInfo(
                              status: SubscriptionStatus.plus,
                              isActive: true,
                              expirationDate:
                                  DateTime.now().add(const Duration(days: 30)),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Test: Switched to PLUS')),
                          );
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.warn[600],
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'TOGGLE SUB',
                        style: TextStyles.small.copyWith(
                          color: theme.grey[50],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, CustomThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final hasSubscription = ref.watch(hasActiveSubscriptionProvider);
        final vaultLayoutSettings = ref.watch(vaultLayoutProvider);
        final orderedAnalytics =
            vaultLayoutSettings.getOrderedVisibleAnalytics();

        // Analytics features map
        final analyticsMap = <String, Widget Function()>{
          'streakAverages': () => _buildAnalyticsFeature(
                context,
                theme,
                hasSubscription,
                AppLocalizations.of(context).translate('streak-averages-title'),
                AppLocalizations.of(context).translate('streak-averages-desc'),
                const StreakAveragesCard(),
                LucideIcons.trendingUp,
                const Color(
                    0xFF22C55E), // Original green from StreakAveragesCard
              ),
          'heatMapCalendar': () => _buildAnalyticsFeature(
                context,
                theme,
                hasSubscription,
                AppLocalizations.of(context)
                    .translate('heat-map-calendar-title'),
                AppLocalizations.of(context)
                    .translate('heat-map-calendar-desc'),
                const HeatMapCalendar(),
                LucideIcons.calendar,
                const Color(0xFFEF4444), // Original red from HeatMapCalendar
              ),
          'triggerRadar': () => _buildAnalyticsFeature(
                context,
                theme,
                hasSubscription,
                AppLocalizations.of(context).translate('trigger-radar-title'),
                AppLocalizations.of(context).translate('trigger-radar-desc'),
                const TriggerRadar(),
                LucideIcons.radar,
                const Color(0xFFF97316), // Original orange from TriggerRadar
              ),
          'riskClock': () => _buildAnalyticsFeature(
                context,
                theme,
                hasSubscription,
                AppLocalizations.of(context).translate('risk-clock-title'),
                AppLocalizations.of(context).translate('risk-clock-desc'),
                const RiskClock(),
                LucideIcons.clock,
                const Color(0xFF06B6D4), // Original cyan from RiskClock
              ),
          'moodCorrelation': () => _buildAnalyticsFeature(
                context,
                theme,
                hasSubscription,
                AppLocalizations.of(context)
                    .translate('mood-correlation-title'),
                AppLocalizations.of(context)
                    .translate('mood-relapse-correlation-desc'),
                const MoodCorrelationChart(),
                LucideIcons.heartHandshake,
                const Color(
                    0xFFEC4899), // Original pink from MoodCorrelationChart
              ),
        };

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)
                    .translate('premium-analytics-title'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
              verticalSpace(Spacing.points16),

              // Render ordered analytics features
              ...orderedAnalytics
                  .expand((analyticsKey) => [
                        if (analyticsMap.containsKey(analyticsKey))
                          analyticsMap[analyticsKey]!(),
                        if (analyticsKey != orderedAnalytics.last)
                          verticalSpace(Spacing.points20),
                      ])
                  .toList()
                ..removeWhere(
                    (widget) => widget == null), // Remove any null widgets
            ],
          ),
        );
      },
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
  ) {
    return Column(
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

        // Content with conditional blur (no container wrapping)
        if (hasSubscription)
          content
        else
          _buildBlurredContent(context, theme, content),
      ],
    );
  }

  Widget _buildBlurredContent(
    BuildContext context,
    CustomThemeData theme,
    Widget content,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (context) => const TaaafiPlusSubscriptionScreen(),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 250, // Limit height to prevent overflow
        ),
        child: Stack(
          children: [
            // Original content (more visible through lighter blur)
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: content,
            ),

            // Progressive blur overlay matching Figma design
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: Container(
                    decoration: BoxDecoration(
                      // Progressive gradient overlay instead of solid white
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            // Lock icon and text overlay (positioned to not completely block content)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primary[600],
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary[600]!.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.lock,
                        color: theme.grey[50],
                        size: 20,
                      ),
                    ),
                    verticalSpace(Spacing.points12),
                    Text(
                      AppLocalizations.of(context).translate('upgrade-to-plus'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      AppLocalizations.of(context)
                          .translate('unlock-premium-analytics'),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
