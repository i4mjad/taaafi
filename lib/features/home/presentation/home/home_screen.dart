import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/notification_promoter_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/quick_access_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/current_streaks_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calendar_section.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/activities_notifications_settings_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/notifications/data/repositories/notifications_repository.dart';
import 'package:reboot_app_3/features/home/presentation/home/home_layout_provider.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/shorebird_update_widget.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final homeLayoutSettings = ref.watch(homeLayoutProvider);
    final locale = ref.watch(localeNotifierProvider);
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final showMainContent = accountStatus == AccountStatus.ok;

    final localization = AppLocalizations.of(context);

    // Watch streak statistics only when we are sure we need to show them to avoid
    // unnecessary calls (and possible exceptions) while the account is still
    // in an incomplete state.
    AsyncValue<StreakStatistics>? streaksState;
    if (showMainContent &&
        (homeLayoutSettings.visibility['currentStreaks'] ?? true)) {
      streaksState = ref.watch(streakNotifierProvider);
    }

    final actions = showMainContent
        ? [
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    context.pushNamed(RouteNames.notifications.name);
                  },
                  icon: Icon(LucideIcons.bell, color: theme.primary[600]),
                ),
                // Badge
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCountAsync =
                        ref.watch(unreadNotificationCountProvider);
                    return unreadCountAsync.when(
                      data: (count) {
                        if (count == 0) return SizedBox.shrink();
                        return Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.error[600],
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: TextStyles.footnote.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => SizedBox.shrink(),
                      error: (_, __) => SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ]
        : null;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'home',
        false,
        false,
        actions: actions,
      ),
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          switch (accountStatus) {
            case AccountStatus.loading:
              return Center(
                child: Spinner(),
              );
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
              // Get ordered elements and build widgets dynamically
              final orderedElements =
                  homeLayoutSettings.getOrderedVisibleElements();

              final widgetMap = <String, Widget>{
                'quickAccess': const QuickAccessSection(),
                'currentStreaks': const CurrentStreaksSection(),
                'statistics': const StatisticsSection(),
                'calendar': const CalendarSection(),
              };

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Shorebird update widget
                    const ShorebirdUpdateWidget(),
                    verticalSpace(Spacing.points16),
                    if (!(notificationsEnabled.value ?? true))
                      const NotificationPromoterWidget(),
                    // Home layout help message (dismissible)
                    if (!homeLayoutSettings.helpMessageDismissed)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: WidgetsContainer(
                          padding: EdgeInsets.all(12),
                          backgroundColor: theme.primary[50],
                          borderSide:
                              BorderSide(color: theme.primary[200]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 20,
                                color: theme.primary[600],
                              ),
                              horizontalSpace(Spacing.points8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('home-layout-help-title'),
                                      style: TextStyles.caption.copyWith(
                                        color: theme.primary[900],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    verticalSpace(Spacing.points8),
                                    Text(
                                      AppLocalizations.of(context).translate(
                                          'home-layout-help-message'),
                                      style: TextStyles.small.copyWith(
                                        color: theme.primary[800],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              horizontalSpace(Spacing.points8),
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(homeLayoutProvider.notifier)
                                      .dismissHelpMessage();
                                },
                                child: Icon(
                                  LucideIcons.x,
                                  size: 18,
                                  color: theme.primary[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Combined Test Screen Access Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: () {
                          context.goNamed(RouteNames.combinedTest.name);
                        },
                        child: WidgetsContainer(
                          padding: EdgeInsets.all(12),
                          backgroundColor: theme.secondary[50],
                          borderSide: BorderSide(
                              color: theme.secondary[200]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.testTube,
                                size: 20,
                                color: theme.secondary[600],
                              ),
                              horizontalSpace(Spacing.points8),
                              Expanded(
                                child: Text(
                                  "Test Combined Dashboard",
                                  style: TextStyles.caption.copyWith(
                                    color: theme.secondary[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.arrowRight,
                                size: 16,
                                color: theme.secondary[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Render ordered elements with consistent spacing
                    ...orderedElements
                        .expand((element) => [
                              widgetMap[element] ?? SizedBox.shrink(),
                              verticalSpace(Spacing.points16),
                            ])
                        .toList()
                      ..removeLast(), // Remove the last spacing
                  ],
                ),
              );
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
}
