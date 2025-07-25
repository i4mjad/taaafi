import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/models/follow_up_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FollowUpHistoryModal extends ConsumerWidget {
  final DateTime? date;
  final int? days;
  final int? dayOfMonth;

  const FollowUpHistoryModal({
    super.key,
    this.date,
    this.days,
    this.dayOfMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with sorting
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getModalTitle(context),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (dayOfMonth != null) ...[
                  GestureDetector(
                    onTap: () {
                      // Toggle sorting - we'll implement this as a simple state toggle
                      // For now, just show a snackbar as placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)
                              .translate('sorting-feature-coming')),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      LucideIcons.arrowUpDown,
                      color: theme.grey[600],
                      size: 20,
                    ),
                  ),
                  horizontalSpace(Spacing.points12),
                ],
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    LucideIcons.x,
                    color: theme.grey[600],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: theme.grey[200]),

          // Content
          Expanded(
            child: FutureBuilder<List<FollowUpModel>>(
              future: _getFilteredFollowUps(ref),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Spinner());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('error-loading-data'),
                      style: TextStyles.body.copyWith(color: theme.error[600]),
                    ),
                  );
                }

                final followUps = snapshot.data ?? [];

                if (followUps.isEmpty) {
                  return _buildEmptyState(context, theme);
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _buildManualGroupedList(context, theme, followUps),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getModalTitle(BuildContext context) {
    if (dayOfMonth != null) {
      return AppLocalizations.of(context).translate('day-of-month-history') +
          ' $dayOfMonth';
    } else if (date != null) {
      final locale = Localizations.localeOf(context);
      final targetDate = date!;
      return getDisplayDate(targetDate, locale.languageCode);
    } else if (days != null) {
      final daysValue = days!;
      if (daysValue == 7) {
        return AppLocalizations.of(context).translate('last-7-days');
      } else if (daysValue == 30) {
        return AppLocalizations.of(context).translate('last-30-days');
      } else if (daysValue == 90) {
        return AppLocalizations.of(context).translate('last-90-days');
      }
    }
    return AppLocalizations.of(context).translate('follow-up-history');
  }

  Future<List<FollowUpModel>> _getFilteredFollowUps(WidgetRef ref) async {
    try {
      final service = ref.read(premiumAnalyticsServiceProvider);
      final allFollowUps = await service.getHeatMapData();

      // Convert to FollowUpModel - with strict validation
      final followUps = allFollowUps
          .where((af) => af.id.isNotEmpty && af.time != null && af.type != null)
          .map((af) => FollowUpModel(
                id: af.id,
                type: af.type,
                time: af.time,
              ))
          .where((f) => f.id.isNotEmpty && f.time != null && f.type != null)
          .toList();

      // Sort manually to avoid GroupedListView sorting issues
      followUps.sort((a, b) {
        try {
          return b.time.compareTo(a.time); // Newest first
        } catch (e) {
          return 0; // If comparison fails, treat as equal
        }
      });

      if (dayOfMonth != null) {
        // Filter by day of month across all time
        final filtered =
            followUps.where((f) => f.time.day == dayOfMonth).toList();
        return filtered;
      } else if (date != null) {
        // Filter by specific date - safe access
        final targetDate = date!;
        final filtered = followUps
            .where((f) =>
                f.time.year == targetDate.year &&
                f.time.month == targetDate.month &&
                f.time.day == targetDate.day)
            .toList();
        return filtered;
      } else if (days != null) {
        // Filter by period - safe access
        final now = DateTime.now();
        final daysValue = days!;
        final startDate = now.subtract(Duration(days: daysValue));
        final filtered =
            followUps.where((f) => f.time.isAfter(startDate)).toList();
        return filtered;
      } else {
        return followUps;
      }
    } catch (e) {
      // Return empty list if there's any error
      print('Error in _getFilteredFollowUps: $e');
      return <FollowUpModel>[];
    }
  }

  Widget _buildEmptyState(BuildContext context, dynamic theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendar,
            color: theme.grey[400],
            size: 48,
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('no-follow-ups-found'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate('start-logging-to-see-data'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManualGroupedList(
      BuildContext context, dynamic theme, List<FollowUpModel> followUps) {
    // Group follow-ups by type
    final groupedFollowUps = <FollowUpType, List<FollowUpModel>>{};
    for (final followUp in followUps) {
      if (groupedFollowUps.containsKey(followUp.type)) {
        groupedFollowUps[followUp.type]!.add(followUp);
      } else {
        groupedFollowUps[followUp.type] = [followUp];
      }
    }

    // Create a list of widgets for each group
    final widgets = <Widget>[];

    for (final type in groupedFollowUps.keys) {
      final followUpsOfType = groupedFollowUps[type]!;

      // Add group header
      widgets.add(Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              _getIconForType(type),
              color: _getColorForType(theme, type),
              size: 20,
            ),
            horizontalSpace(Spacing.points8),
            Text(
              _getTypeLabel(context, type),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getColorForType(theme, type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${followUpsOfType.length}',
                style: TextStyles.small.copyWith(
                  color: _getColorForType(theme, type),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ));

      // Add follow-up items for this group
      for (final followUp in followUpsOfType) {
        widgets.add(Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.grey[200] ?? Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getColorForType(theme, followUp.type),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getDisplayDate(followUp.time,
                          Localizations.localeOf(context).languageCode),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      _formatTime(followUp.time),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }

      // Add spacing after each group
      widgets.add(verticalSpace(Spacing.points16));
    }

    return ListView(
      children: widgets,
    );
  }

  IconData _getIconForType(FollowUpType type) {
    switch (type) {
      case FollowUpType.relapse:
        return LucideIcons.heartCrack;
      case FollowUpType.pornOnly:
        return LucideIcons.play;
      case FollowUpType.mastOnly:
        return LucideIcons.hand;
      case FollowUpType.slipUp:
        return LucideIcons.planeLanding;
      case FollowUpType.none:
        return LucideIcons.clock;
    }
  }

  Color _getColorForType(dynamic theme, FollowUpType type) {
    return followUpColors[type] ?? theme.grey[500];
  }

  String _getTypeLabel(BuildContext context, FollowUpType type) {
    switch (type) {
      case FollowUpType.none:
        return AppLocalizations.of(context).translate('clean-day');
      case FollowUpType.slipUp:
        return AppLocalizations.of(context).translate('slip-up-day');
      case FollowUpType.relapse:
        return AppLocalizations.of(context).translate('relapse-day');
      case FollowUpType.pornOnly:
        return AppLocalizations.of(context).translate('porn-only-day');
      case FollowUpType.mastOnly:
        return AppLocalizations.of(context).translate('mast-only-day');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
