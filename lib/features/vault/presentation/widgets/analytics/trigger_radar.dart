import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/models/analytics_follow_up.dart';

class TriggerRadar extends ConsumerWidget {
  const TriggerRadar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final triggerDataAsync = ref.watch(triggerRadarDataProvider);

    return WidgetsContainer(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      backgroundColor: theme.grey[50],
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                LucideIcons.radar,
                color: Color(0xFFF97316),
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Text(
                AppLocalizations.of(context).translate('trigger-radar-title'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate('trigger-radar-desc'),
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
          verticalSpace(Spacing.points20),

          // Radar chart
          triggerDataAsync.when(
            data: (triggerCounts) {
              if (_getTotalCount(triggerCounts) < 3) {
                return _buildEmptyState(context, theme);
              }
              return _buildRadarChart(context, theme, triggerCounts);
            },
            loading: () => Center(child: Spinner()),
            error: (_, __) => _buildEmptyState(context, theme),
          ),
        ],
      ),
    );
  }

  int _getTotalCount(Map<String, int> triggerCounts) {
    return triggerCounts.values.fold(0, (sum, count) => sum + count);
  }

  Widget _buildRadarChart(
      BuildContext context, dynamic theme, Map<String, int> triggerCounts) {
    // Get the top triggers for the radar chart
    final topTriggers = CommonTriggers.triggers.take(6).toList();
    final maxCount =
        triggerCounts.values.fold(1, (max, count) => count > max ? count : max);

    return AspectRatio(
      aspectRatio: 1.3,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showTriggerDetails(context, triggerCounts);
        },
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            radarBackgroundColor: Colors.transparent,
            radarBorderData: BorderSide(color: theme.grey[300]!, width: 1),
            tickCount: 4,
            tickBorderData: BorderSide(color: theme.grey[200]!, width: 0.5),
            gridBorderData: BorderSide(color: theme.grey[200]!, width: 0.5),
            titleTextStyle: TextStyles.small.copyWith(
              color: theme.grey[700],
              fontWeight: FontWeight.w500,
            ),
            getTitle: (index, angle) {
              if (index >= topTriggers.length) return RadarChartTitle(text: '');
              final trigger = topTriggers[index];
              return RadarChartTitle(
                text:
                    AppLocalizations.of(context).translate('trigger-$trigger'),
              );
            },
            dataSets: [
              RadarDataSet(
                dataEntries: topTriggers.map((trigger) {
                  final count = triggerCounts[trigger] ?? 0;
                  return RadarEntry(value: count / maxCount * 100);
                }).toList(),
                fillColor: Color(0xFFF97316).withValues(alpha: 0.3),
                borderColor: Color(0xFFF97316),
                borderWidth: 2,
                entryRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic theme) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.target,
              color: theme.grey[400],
              size: 32,
            ),
            verticalSpace(Spacing.points12),
            Text(
              AppLocalizations.of(context).translate('trigger-empty'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTriggerDetails(
      BuildContext context, Map<String, int> triggerCounts) {
    final theme = AppTheme.of(context);

    // Sort triggers by count
    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('trigger-radar-title'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            verticalSpace(Spacing.points20),
            ...sortedTriggers.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('trigger-${entry.key}'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF97316).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value} ${AppLocalizations.of(context).translate('times')}',
                          style: TextStyles.footnote.copyWith(
                            color: Color(0xFFF97316),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            verticalSpace(Spacing.points20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    color: theme.primary[600],
                    size: 20,
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('trigger-tip'),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
