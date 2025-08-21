import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

class GroupNotificationSettingsScreen extends ConsumerStatefulWidget {
  const GroupNotificationSettingsScreen({super.key});

  @override
  ConsumerState<GroupNotificationSettingsScreen> createState() =>
      _GroupNotificationSettingsScreenState();
}

class _GroupNotificationSettingsScreenState
    extends ConsumerState<GroupNotificationSettingsScreen> {
  bool _enableNotifications = true;
  bool _messageNotifications = true;
  bool _updateNotifications = true;
  bool _challengeReminders = true;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "notification-settings", false, true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Enable Notifications
            WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: PlatformSwitch(
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() {
                    _enableNotifications = value;
                  });
                },
                label: l10n.translate('enable-notifications'),
              ),
            ),

            verticalSpace(Spacing.points8),

            // Message Notifications
            WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: PlatformSwitch(
                value: _messageNotifications,
                onChanged: _enableNotifications
                    ? (value) {
                        setState(() {
                          _messageNotifications = value;
                        });
                      }
                    : null,
                label: l10n.translate('message-notifications'),
              ),
            ),

            verticalSpace(Spacing.points8),

            // Update Notifications
            WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: PlatformSwitch(
                value: _updateNotifications,
                onChanged: _enableNotifications
                    ? (value) {
                        setState(() {
                          _updateNotifications = value;
                        });
                      }
                    : null,
                label: l10n.translate('update-notifications'),
              ),
            ),

            verticalSpace(Spacing.points8),

            // Challenge Reminders
            WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: PlatformSwitch(
                value: _challengeReminders,
                onChanged: _enableNotifications
                    ? (value) {
                        setState(() {
                          _challengeReminders = value;
                        });
                      }
                    : null,
                label: l10n.translate('challenge-reminders'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
