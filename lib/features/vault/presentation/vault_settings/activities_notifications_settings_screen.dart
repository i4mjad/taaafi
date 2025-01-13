import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class ActivitiesNotificationsSettingsScreen extends ConsumerWidget {
  const ActivitiesNotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
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
                  WidgetsContainer(
                    borderRadius: BorderRadius.circular(16),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(
                      color: theme.grey[900]!,
                      width: 0.25,
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.bell, color: theme.primary[600]),
                      ],
                    ),
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

class ActivateNotification extends ConsumerWidget {
  const ActivateNotification({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  style: TextStyles.caption.copyWith(color: theme.grey[600]),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            activeTrackColor: theme.primary[600],
            onChanged: (value) {
              //TODO: handle the switch
            },
          ),
        ],
      ),
    );
  }
}
