import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/ongoing_activitiy_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/update_ongoing_activity_sheet.dart';

class OngoingActivitySettingsSheet extends ConsumerWidget {
  const OngoingActivitySettingsSheet(this.ongoingActivityId, {super.key});

  final String ongoingActivityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = Localizations.localeOf(context);
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
                AppLocalizations.of(context).translate('activity-settings'),
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
          SettingsOption(
            onTap: () {
              Navigator.pop(context);
              context.goNamed(RouteNames.activitiesNotifications.name);
            },
            text: "activity-notifications",
            icon: LucideIcons.alarmPlus,
            type: "primary",
          ),
          verticalSpace(Spacing.points8),
          SettingsOption(
            onTap: () {
              _showExtendActivityDialog(context, ref, locale);
            },
            text: "extend-activity",
            icon: LucideIcons.calendarPlus,
            type: "normal",
          ),
          verticalSpace(Spacing.points8),
          SettingsOption(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return UpdateOngoingActivitySheet(ongoingActivityId);
                },
              );
            },
            text: "new-begining",
            icon: LucideIcons.listStart,
            type: "warn",
          ),
          verticalSpace(Spacing.points8),
          SettingsOption(
            onTap: () => _showDeleteConfirmation(context, ref),
            text: "remove-activity",
            icon: LucideIcons.trash2,
            type: "error",
          ),
          verticalSpace(Spacing.points32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.grey[900]!, width: 0.5),
              boxShadow: Shadows.mainShadows,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('close'),
                  style: TextStyles.body.copyWith(color: theme.primary[900]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref) async {
    final theme = AppTheme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        title: Text(
          AppLocalizations.of(context).translate('warning'),
          style: TextStyles.h6.copyWith(color: theme.error[700]),
        ),
        content: Text(
          AppLocalizations.of(context).translate('delete-activity-warning'),
          style: TextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Delete the activity
              await ref
                  .read(
                      ongoingActivityDetailsNotifierProvider(ongoingActivityId)
                          .notifier)
                  .deleteActivity();
              // First pop the dialog
              Navigator.pop(dialogContext);
              // Then pop the settings sheet
              Navigator.pop(context);

              // Navigate using a delayed call to ensure previous operations are complete
              if (context.mounted) {
                Future.microtask(() {
                  context.goNamed(RouteNames.activities.name);
                });
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyles.body.copyWith(color: theme.error[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExtendActivityDialog(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
  ) async {
    final theme = AppTheme.of(context);
    Duration? selectedDuration;

    final Map<Duration, String> extensionOptions = {
      const Duration(days: 7):
          AppLocalizations.of(context).translate('one-week'),
      const Duration(days: 30):
          AppLocalizations.of(context).translate('one-month'),
      const Duration(days: 90):
          AppLocalizations.of(context).translate('three-months'),
    };

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.backgroundColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('extend-activity'),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              ),
            ],
          ),
          content: DropdownButtonFormField<Duration>(
            value: selectedDuration,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.grey[300]!),
              ),
              filled: true,
              fillColor: theme.backgroundColor,
            ),
            hint: Text(
              AppLocalizations.of(context).translate('select-extension-period'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
            items: extensionOptions.entries.map((entry) {
              return DropdownMenuItem<Duration>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: TextStyles.body.copyWith(color: theme.grey[900]),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedDuration = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context).translate('cancel'),
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            ),
            TextButton(
              onPressed: selectedDuration == null
                  ? null
                  : () {
                      _handleExtension(context, ref, selectedDuration!, locale);
                    },
              child: Text(
                AppLocalizations.of(context).translate('confirm'),
                style: TextStyles.body.copyWith(
                  color: selectedDuration == null
                      ? theme.grey[400]
                      : theme.primary[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExtension(BuildContext context, WidgetRef ref,
      Duration period, Locale locale) async {
    final success = await ref
        .read(
            ongoingActivityDetailsNotifierProvider(ongoingActivityId).notifier)
        .extendActivity(period, locale, context);

    if (success) {
      Navigator.pop(context); // Close dialog
      getSuccessSnackBar(context, 'activity-extended');
    } else {
      Navigator.pop(context); // Close dialog
      getErrorSnackBar(context, 'error-extend-activity');
    }
  }
}
