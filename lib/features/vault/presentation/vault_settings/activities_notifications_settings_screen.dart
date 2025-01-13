import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/notifications/notifications_scheduler.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activities_notifier.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity.dart';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ActivitiesNotificationsSettingsScreen extends ConsumerWidget {
  const ActivitiesNotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final ongoingActivities = ref.watch(ongoingActivitiesNotifierProvider);
    return Scaffold(
      appBar: appBar(
        context,
        ref,
        "activities-notifications-settings",
        false,
        true,
      ),
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ActivateNotification(),
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context)
                        .translate('ongoing-activities'),
                    style: TextStyles.h6.copyWith(color: theme.grey[900]),
                  ),
                  verticalSpace(Spacing.points8),
                  ongoingActivities.when(
                    data: (ongoingActivities) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: ongoingActivities.length,
                        itemBuilder: (context, index) {
                          return OngoingActivityCard(
                            ongoingActivity: ongoingActivities[index],
                          );
                        },
                      );
                    },
                    error: (error, stackTrace) {
                      return Text(error.toString());
                    },
                    loading: () {
                      return Text('Loading...');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OngoingActivityCard extends ConsumerStatefulWidget {
  const OngoingActivityCard({
    required this.ongoingActivity,
    super.key,
  });

  final OngoingActivity ongoingActivity;

  @override
  ConsumerState<OngoingActivityCard> createState() =>
      _OngoingActivityCardState();
}

class _OngoingActivityCardState extends ConsumerState<OngoingActivityCard> {
  late bool _hasNotifications;

  @override
  void initState() {
    super.initState();
    _hasNotifications = NotificationsScheduler.instance
        .hasScheduledNotifications(widget.ongoingActivity.id);
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final theme = AppTheme.of(context);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        title: Text(title,
            style: TextStyles.h6.copyWith(color: theme.success[600])),
        content: Text(message,
            style: TextStyles.body.copyWith(color: theme.grey[900])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyles.small.copyWith(color: theme.grey[800]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              AppLocalizations.of(context).translate('confirm'),
              style: TextStyles.small.copyWith(color: theme.success[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final theme = AppTheme.of(context);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        title:
            Text(title, style: TextStyles.h6.copyWith(color: theme.error[600])),
        content: Text(message,
            style: TextStyles.body.copyWith(color: theme.grey[900])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyles.small.copyWith(color: theme.grey[800]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              AppLocalizations.of(context).translate('confirm'),
              style: TextStyles.small.copyWith(color: theme.error[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleActivate() async {
    final locale = ref.watch(localeNotifierProvider);
    await _showConfirmationDialog(
      title: AppLocalizations.of(context).translate('activate-notifications'),
      message: AppLocalizations.of(context)
          .translate('activate-notifications-confirmation'),
      onConfirm: () async {
        await NotificationsScheduler.instance
            .scheduleNotificationsForOngoingActivity(
                widget.ongoingActivity, locale!);
        setState(() {
          _hasNotifications = true;
        });
      },
    );
  }

  Future<void> _handleCancel() async {
    await _showCancelConfirmationDialog(
      title: AppLocalizations.of(context).translate('cancel-notifications'),
      message: AppLocalizations.of(context)
          .translate('cancel-notifications-confirmation'),
      onConfirm: () async {
        await NotificationsScheduler.instance
            .cancelNotificationsForActivity(widget.ongoingActivity.id);
        setState(() {
          _hasNotifications = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: theme.grey[900]!,
        width: 0.25,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.ongoingActivity.activity!.name,
            style: TextStyles.footnote.copyWith(color: theme.grey[900]),
            overflow: TextOverflow.visible,
          ),
          _hasNotifications
              ? GestureDetector(
                  onTap: _handleCancel,
                  child: WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    padding: EdgeInsets.all(8),
                    borderSide:
                        BorderSide(color: theme.error[500]!, width: 0.5),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('cancel-notifications'),
                        style:
                            TextStyles.small.copyWith(color: theme.error[500]),
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _handleActivate,
                  child: WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    padding: EdgeInsets.all(8),
                    borderSide:
                        BorderSide(color: theme.secondary[600]!, width: 0.5),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('activate'),
                        style: TextStyles.small
                            .copyWith(color: theme.secondary[800]),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class ActivateNotification extends ConsumerStatefulWidget {
  const ActivateNotification({
    super.key,
  });

  @override
  ConsumerState<ActivateNotification> createState() =>
      _ActivateNotificationState();
}

class _ActivateNotificationState extends ConsumerState<ActivateNotification> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    setState(() {
      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }

  Future<void> _handleSwitchChange(bool value) async {
    // Open app settings when switch is toggled
    await AppSettings.openAppSettings(type: AppSettingsType.notification);

    // Check permission status after returning from settings
    await _checkNotificationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      borderRadius: BorderRadius.circular(16),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: theme.grey[900]!,
        width: 0.25,
      ),
      boxShadow: Shadows.mainShadows,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            LucideIcons.bell,
            color: theme.primary[600],
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .translate('activities-notifications-settings'),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context)
                      .translate('allow-notifications-desc'),
                  style: TextStyles.footnote.copyWith(color: theme.grey[600]),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context).translate(_notificationsEnabled
                      ? 'notifications-allowed'
                      : 'notifications-disabled'),
                  style: TextStyles.smallBold.copyWith(
                    color: _notificationsEnabled
                        ? theme.success[600]
                        : theme.error[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            activeTrackColor: theme.primary[600],
            onChanged: _handleSwitchChange,
          ),
        ],
      ),
    );
  }
}
