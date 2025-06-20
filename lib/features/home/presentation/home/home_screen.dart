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
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';

// Home visibility provider
final homeVisibilityProvider =
    StateNotifierProvider<HomeVisibilityNotifier, Map<String, bool>>((ref) {
  return HomeVisibilityNotifier();
});

class HomeVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  HomeVisibilityNotifier()
      : super({
          'quickAccess': true,
          'statistics': true,
          'calendar': true,
          'currentStreaks': true,
        }) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final quickAccess = prefs.getBool('home_quick_access_visible') ?? true;
    final statistics = prefs.getBool('home_statistics_visible') ?? true;
    final calendar = prefs.getBool('home_calendar_visible') ?? true;
    final currentStreaks =
        prefs.getBool('home_current_streaks_visible') ?? true;

    state = {
      'quickAccess': quickAccess,
      'statistics': statistics,
      'calendar': calendar,
      'currentStreaks': currentStreaks,
    };
  }

  Future<void> toggleVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_${key}_visible', value);

    state = {
      ...state,
      key: value,
    };
  }
}

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final homeVisibilitySettings = ref.watch(homeVisibilityProvider);
    final locale = ref.watch(localeNotifierProvider);
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final showMainContent = accountStatus == AccountStatus.ok;

    final localization = AppLocalizations.of(context);

    // Watch streak statistics only when we are sure we need to show them to avoid
    // unnecessary calls (and possible exceptions) while the account is still
    // in an incomplete state.
    AsyncValue<StreakStatistics>? streaksState;
    if (showMainContent && (homeVisibilitySettings['currentStreaks'] ?? true)) {
      streaksState = ref.watch(streakNotifierProvider);
    }

    final actions = showMainContent
        ? [
            IconButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return HomeSettingsSheet();
                  },
                );
              },
              icon: Icon(LucideIcons.listChecks, color: theme.primary[600]),
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
            case AccountStatus.ok:
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!(notificationsEnabled.value ?? true))
                      const NotificationPromoterWidget(),
                    if (homeVisibilitySettings['quickAccess'] ?? true)
                      QuickAccessWidget(),
                    if (homeVisibilitySettings['quickAccess'] ?? true)
                      verticalSpace(Spacing.points4),
                    if (homeVisibilitySettings['currentStreaks'] ?? true)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("current-streaks"),
                                  style: TextStyles.h6
                                      .copyWith(color: theme.grey[900]),
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
                                          final firstDate = streaksState
                                              ?.value?.userFirstDate;
                                          return firstDate != null
                                              ? getDisplayDateTime(firstDate,
                                                  locale!.languageCode)
                                              : localization
                                                  .translate("not-set");
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
                    if (homeVisibilitySettings['statistics'] ?? true)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate("statistics"),
                              style: TextStyles.h6
                                  .copyWith(color: theme.grey[900]),
                            ),
                            UserStatisticsWidget(),
                          ],
                        ),
                      ),
                    if (homeVisibilitySettings['calendar'] ?? true)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CalenderWidget(),
                      )
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
    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, top: 12),
      child: Column(
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
      ),
    );
  }
}

class HomeSettingsSheet extends ConsumerWidget {
  const HomeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = Localizations.localeOf(context);
    final homeVisibilitySettings = ref.watch(homeVisibilityProvider);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('home-settings'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),

          // Home Elements Visibility Section
          Text(
            AppLocalizations.of(context).translate('home-elements-visibility'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate('home-elements-visibility-description'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points8),

          // Quick Access Option
          IntrinsicHeight(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(homeVisibilityProvider.notifier).toggleVisibility(
                      'quickAccess',
                      !homeVisibilitySettings['quickAccess']!,
                    );
              },
              child: WidgetsContainer(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: homeVisibilitySettings['quickAccess']!
                    ? theme.success[50]
                    : theme.backgroundColor,
                borderSide: BorderSide(
                  color: homeVisibilitySettings['quickAccess']!
                      ? theme.success[600]!
                      : theme.grey[200]!,
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.layoutGrid,
                          size: 16,
                          color: homeVisibilitySettings['quickAccess']!
                              ? theme.success[600]
                              : theme.grey[600],
                        ),
                        horizontalSpace(Spacing.points4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('quick-access'),
                            style: TextStyles.caption.copyWith(
                              color: homeVisibilitySettings['quickAccess']!
                                  ? theme.success[600]
                                  : theme.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('quick-access-description'),
                      style: TextStyles.small.copyWith(
                        color: homeVisibilitySettings['quickAccess']!
                            ? theme.success[400]
                            : theme.grey[400],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points8),

          // Current Streaks Option
          IntrinsicHeight(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(homeVisibilityProvider.notifier).toggleVisibility(
                      'currentStreaks',
                      !homeVisibilitySettings['currentStreaks']!,
                    );
              },
              child: WidgetsContainer(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: homeVisibilitySettings['currentStreaks']!
                    ? theme.success[50]
                    : theme.backgroundColor,
                borderSide: BorderSide(
                  color: homeVisibilitySettings['currentStreaks']!
                      ? theme.success[600]!
                      : theme.grey[200]!,
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.timer,
                          size: 16,
                          color: homeVisibilitySettings['currentStreaks']!
                              ? theme.success[600]
                              : theme.grey[600],
                        ),
                        horizontalSpace(Spacing.points4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('current-streaks'),
                            style: TextStyles.caption.copyWith(
                              color: homeVisibilitySettings['currentStreaks']!
                                  ? theme.success[600]
                                  : theme.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('current-streaks-description'),
                      style: TextStyles.small.copyWith(
                        color: homeVisibilitySettings['currentStreaks']!
                            ? theme.success[400]
                            : theme.grey[400],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points8),

          // Statistics Option
          IntrinsicHeight(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(homeVisibilityProvider.notifier).toggleVisibility(
                      'statistics',
                      !homeVisibilitySettings['statistics']!,
                    );
              },
              child: WidgetsContainer(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: homeVisibilitySettings['statistics']!
                    ? theme.success[50]
                    : theme.backgroundColor,
                borderSide: BorderSide(
                  color: homeVisibilitySettings['statistics']!
                      ? theme.success[600]!
                      : theme.grey[200]!,
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.barChart2,
                          size: 16,
                          color: homeVisibilitySettings['statistics']!
                              ? theme.success[600]
                              : theme.grey[600],
                        ),
                        horizontalSpace(Spacing.points4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('statistics'),
                            style: TextStyles.caption.copyWith(
                              color: homeVisibilitySettings['statistics']!
                                  ? theme.success[600]
                                  : theme.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('statistics-description'),
                      style: TextStyles.small.copyWith(
                        color: homeVisibilitySettings['statistics']!
                            ? theme.success[400]
                            : theme.grey[400],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points8),

          // Calendar Option
          IntrinsicHeight(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(homeVisibilityProvider.notifier).toggleVisibility(
                      'calendar',
                      !homeVisibilitySettings['calendar']!,
                    );
              },
              child: WidgetsContainer(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: homeVisibilitySettings['calendar']!
                    ? theme.success[50]
                    : theme.backgroundColor,
                borderSide: BorderSide(
                  color: homeVisibilitySettings['calendar']!
                      ? theme.success[600]!
                      : theme.grey[200]!,
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: homeVisibilitySettings['calendar']!
                              ? theme.success[600]
                              : theme.grey[600],
                        ),
                        horizontalSpace(Spacing.points4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).translate('calendar'),
                            style: TextStyles.caption.copyWith(
                              color: homeVisibilitySettings['calendar']!
                                  ? theme.success[600]
                                  : theme.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('calendar-description'),
                      style: TextStyles.small.copyWith(
                        color: homeVisibilitySettings['calendar']!
                            ? theme.success[400]
                            : theme.grey[400],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          verticalSpace(Spacing.points16),

          // Save button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.primary[600],
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('close'),
                  style: TextStyles.h6.copyWith(color: theme.grey[50]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsOption extends StatelessWidget {
  const SettingsOption({
    required this.onTap,
    required this.text,
    required this.icon,
    required this.type,
    this.isChecked = false,
    super.key,
  });

  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final String type;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(4),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                activeColor: theme.primary[600],
                value: isChecked,
                onChanged: (value) => onTap(),
              ),
              Text(
                AppLocalizations.of(context).translate(text),
                style: TextStyles.small
                    .copyWith(color: _getIconAndTextColor(type, theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconAndTextColor(String type, CustomThemeData theme) {
    switch (type) {
      case 'error':
        return theme.error[600]!;
      case 'primary':
        return theme.primary[600]!;
      case 'warn':
        return theme.warn[600]!;
      case 'normal':
      default:
        return theme.grey[800]!;
    }
  }
}
