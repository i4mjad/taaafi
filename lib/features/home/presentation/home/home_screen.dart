import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/follow_up_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calender_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';
import 'package:app_settings/app_settings.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/activities_notifications_settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final streaksState = ref.watch(streakNotifierProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final actions = [
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
        icon: Icon(LucideIcons.settings, color: theme.primary[600]),
      ),
    ];
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, false, actions: actions),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!(notificationsEnabled.value ?? true))
              const NotificationPromoterWidget(),
            Activities(),
            verticalSpace(Spacing.points4),
            StatisticsWidget(),
            verticalSpace(Spacing.points8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CalenderWidget(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
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

class Activities extends ConsumerWidget {
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
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);

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
          Text(
            AppLocalizations.of(context).translate('statistics-visibility'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate('statistics-visibility-description'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'relapse',
                          !visibilitySettings['relapse']!,
                        );
                  },
                  text: "relapses",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['relapse']!,
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'pornOnly',
                          !visibilitySettings['pornOnly']!,
                        );
                  },
                  text: "porn",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['pornOnly']!,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'mastOnly',
                          !visibilitySettings['mastOnly']!,
                        );
                  },
                  text: "mast",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['mastOnly']!,
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'slipUp',
                          !visibilitySettings['slipUp']!,
                        );
                  },
                  text: "slips",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['slipUp']!,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('delete-duplicates'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate('delete-duplicates-description'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points8),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref
                  .read(followUpNotifierProvider.notifier)
                  .cleanupDuplicateFollowUps();
              getSuccessSnackBar(context, "duplicates-deleted");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.backgroundColor,
              minimumSize: const Size.fromHeight(48),
              shape: SmoothRectangleBorder(
                side: BorderSide(color: theme.grey[600]!, width: 0.25),
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 10.5,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('delete-duplicates'),
              style: TextStyles.caption.copyWith(color: theme.primary[600]),
            ),
          ),
          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(statisticsVisibilityProvider.notifier)
                        .savePreferences();
                    Navigator.pop(context);
                  },
                  child: WidgetsContainer(
                    backgroundColor: theme.primary[600],
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('save'),
                        style: TextStyles.h6.copyWith(color: theme.grey[50]),
                      ),
                    ),
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[900]!, width: 0.5),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('close'),
                        style:
                            TextStyles.h6.copyWith(color: theme.primary[900]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
