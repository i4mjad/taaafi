import 'package:flutter/material.dart';
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
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activities_notifier.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_notifier.dart';

class VaultSettingsScreen extends ConsumerWidget {
  const VaultSettingsScreen({super.key});

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
                  Text(
                    AppLocalizations.of(context)
                        .translate('activities-settings'),
                    style: TextStyles.h6,
                  ),
                  verticalSpace(Spacing.points8),
                  GestureDetector(
                    onTap: () => context
                        .goNamed(RouteNames.activitiesNotifications.name),
                    child: VaultSettingsButton(
                      icon: LucideIcons.bell,
                      textKey: 'activities-reminders',
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  GestureDetector(
                    onTap: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.backgroundColor,
                          title: Text(
                            AppLocalizations.of(context).translate(
                                'delete-activities-confirmation-title'),
                            style: TextStyles.h6.copyWith(
                              color: theme.error[600],
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context).translate(
                                'delete-activities-confirmation-message'),
                            style: TextStyles.body,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate('cancel'),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate('confirm'),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.error[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        await ref
                            .read(ongoingActivitiesNotifierProvider.notifier)
                            .deleteAllActivities();
                        getSuccessSnackBar(context, 'activities-deleted');
                      }
                    },
                    child: VaultSettingsButton(
                      icon: LucideIcons.trash2,
                      textKey: 'erase-all-activities',
                      type: 'warn',
                    ),
                  ),

                  // Text(
                  //   AppLocalizations.of(context)
                  //       .translate('bookmarks-settings'),
                  //   style: TextStyles.h6,
                  // ),
                  // verticalSpace(Spacing.points8),
                  // VaultSettingsButton(
                  //   icon: LucideIcons.trash2,
                  //   textKey: 'erase-all-bookmarks',
                  //   type: 'warn',
                  // ),
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context).translate('diaries-settings'),
                    style: TextStyles.h6,
                  ),
                  verticalSpace(Spacing.points8),
                  GestureDetector(
                    onTap: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.backgroundColor,
                          title: Text(
                            AppLocalizations.of(context)
                                .translate('delete-diaries-confirmation-title'),
                            style: TextStyles.h6.copyWith(
                              color: theme.error[600],
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context).translate(
                                'delete-diaries-confirmation-message'),
                            style: TextStyles.body,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate('cancel'),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate('confirm'),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.error[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        await ref
                            .read(diariesNotifierProvider.notifier)
                            .deleteAllDiaries();
                        getSuccessSnackBar(context, 'diaries-deleted');
                      }
                    },
                    child: VaultSettingsButton(
                      icon: LucideIcons.trash2,
                      textKey: 'erase-all-diaries',
                      type: 'warn',
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

class VaultSettingsButton extends StatelessWidget {
  final IconData icon;
  final String textKey;
  final String? type;
  final VoidCallback? action;
  const VaultSettingsButton(
      {super.key,
      required this.icon,
      required this.textKey,
      this.type,
      this.action});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: WidgetsContainer(
          padding: EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(
              color: type == 'warn' ? theme.error[500]! : theme.grey[600]!,
              width: 0.5),
          borderRadius: BorderRadius.circular(10.5),
          boxShadow: Shadows.mainShadows,
          child: Row(
            children: [
              Icon(
                icon,
                color: type == 'warn' ? theme.error[500] : theme.grey[900],
              ),
              horizontalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context).translate(textKey),
                style: TextStyles.footnote
                    .copyWith(color: _getTextColor(type, theme)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getTextColor(String? type, CustomThemeData theme) {
    switch (type) {
      case 'warn':
        return theme.error[500] as Color;
      case 'app':
        return theme.primary[600] as Color;
      default:
        return theme.grey[900] as Color;
    }
  }
}
