import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/data/models/streak_statistics.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calender_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';
import 'package:app_settings/app_settings.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/streak_settings_sheet.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/activities_notifications_settings_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/notifications/data/repositories/notifications_repository.dart';
import 'package:reboot_app_3/features/home/presentation/home/home_layout_provider.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          switch (accountStatus) {
            case AccountStatus.loading:
              return Center(
                child: CircularProgressIndicator(
                  color: theme.primary[600],
                ),
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
                'quickAccess': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: QuickAccessWidget(),
                ),
                'currentStreaks': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate("current-streaks"),
                            style:
                                TextStyles.h6.copyWith(color: theme.grey[900]),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return StreakSettingsSheet();
                                },
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate("customize"),
                              style: TextStyles.small.copyWith(
                                  color: theme.grey[600],
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      verticalSpace(Spacing.points4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: theme.grey[400],
                          ),
                          horizontalSpace(Spacing.points8),
                          Expanded(
                            child: Text(
                              localization.translate("starting-date") +
                                  ": " +
                                  (() {
                                    final firstDate =
                                        streaksState?.value?.userFirstDate;
                                    return firstDate != null
                                        ? getDisplayDateTime(
                                            firstDate, locale!.languageCode)
                                        : localization.translate("not-set");
                                  })(),
                              style: TextStyles.small.copyWith(
                                color: theme.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (streaksState != null) CurrentStreaksWidget(),
                    ],
                  ),
                ),
                'statistics': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate("statistics"),
                        style: TextStyles.h6.copyWith(color: theme.grey[900]),
                      ),
                      UserStatisticsWidget(),
                    ],
                  ),
                ),
                'calendar': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CalenderWidget(),
                ),
              };

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
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

class NotificationPromoterWidget extends ConsumerWidget {
  const NotificationPromoterWidget({super.key});

  Future<void> _handleNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _handleNotificationSettings,
        child: WidgetsContainer(
          borderRadius: BorderRadius.circular(16),
          backgroundColor: theme.success[50],
          borderSide: BorderSide(
            color: theme.success[200]!,
            width: 0.5,
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bellRing,
                color: theme.success[900],
                // size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .translate('notification-promotion'),
                  style: TextStyles.footnote
                      .copyWith(color: theme.grey[600], height: 1.4),
                ),
              ),
              horizontalSpace(Spacing.points4),
              GestureDetector(
                onTap: _handleNotificationSettings,
                child: Text(
                  AppLocalizations.of(context).translate('enable'),
                  style: TextStyles.smallBold.copyWith(
                    color: theme.success[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAccessWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate("quick-access"),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(RouteNames.activities.name);
                },
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[100]!, width: 1),
                  boxShadow: Shadows.mainShadows,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.clipboardCheck,
                        size: 18,
                        color: theme.primary[900],
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        AppLocalizations.of(context).translate("activities"),
                        style: TextStyles.footnote
                            .copyWith(color: theme.grey[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            horizontalSpace(Spacing.points8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(RouteNames.library.name);
                },
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[100]!, width: 1),
                  boxShadow: Shadows.mainShadows,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.lamp,
                        size: 18,
                        color: theme.primary[900],
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        AppLocalizations.of(context).translate("library"),
                        style: TextStyles.footnote
                            .copyWith(color: theme.grey[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            horizontalSpace(Spacing.points8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(RouteNames.diaries.name);
                },
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[100]!, width: 1),
                  boxShadow: Shadows.mainShadows,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 18,
                        color: theme.primary[900],
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        AppLocalizations.of(context).translate("diaries"),
                        style: TextStyles.footnote
                            .copyWith(color: theme.grey[900]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
