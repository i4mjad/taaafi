import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/analytics/analytics_notifier.dart';

class TriggerRadar extends ConsumerWidget {
  const TriggerRadar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final triggerDataAsync = ref.watch(triggerRadarDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radar chart content
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
    );
  }

  int _getTotalCount(Map<String, int> triggerCounts) {
    return triggerCounts.values.fold(0, (sum, count) => sum + count);
  }

  Widget _buildRadarChart(
      BuildContext context, dynamic theme, Map<String, int> triggerCounts) {
    // Get the top 6 most frequent triggers from actual data
    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTriggers = sortedTriggers.take(6).map((e) => e.key).toList();

    // If we don't have enough triggers, fill up to 6 with empty entries
    while (topTriggers.length < 6) {
      topTriggers.add('');
    }

    final maxCount =
        triggerCounts.values.fold(1, (max, count) => count > max ? count : max);

    return Column(
      children: [
        // How to read button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showHowToReadModal(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primary[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primary[200]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.helpCircle,
                  color: theme.primary[600],
                  size: 16,
                ),
                horizontalSpace(Spacing.points8),
                Text(
                  AppLocalizations.of(context)
                      .translate('how-to-read-trigger-radar'),
                  style: TextStyles.small.copyWith(
                    color: theme.primary[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                horizontalSpace(Spacing.points4),
                Icon(
                  LucideIcons.externalLink,
                  color: theme.primary[600],
                  size: 12,
                ),
              ],
            ),
          ),
        ),
        verticalSpace(Spacing.points12),
        AspectRatio(
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
                ticksTextStyle: TextStyles.small.copyWith(
                  color: theme.grey[600],
                  fontSize: 10,
                ),
                titleTextStyle: TextStyles.small.copyWith(
                  color: theme.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                getTitle: (index, angle) {
                  if (index >= topTriggers.length ||
                      topTriggers[index].isEmpty) {
                    return RadarChartTitle(text: '');
                  }
                  final trigger = topTriggers[index];
                  return RadarChartTitle(
                    text: AppLocalizations.of(context).translate(trigger),
                  );
                },
                dataSets: [
                  RadarDataSet(
                    dataEntries: topTriggers.map((trigger) {
                      if (trigger.isEmpty) return RadarEntry(value: 0);
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
        ),
      ],
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

  void _showHowToReadModal(BuildContext context) {
    final theme = AppTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;

        return Container(
          height: availableHeight * 0.85,
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.primary[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.target,
                      color: theme.primary[600],
                      size: 24,
                    ),
                    horizontalSpace(Spacing.points12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('how-to-read-trigger-radar'),
                        style: TextStyles.h5.copyWith(
                          color: theme.primary[800],
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        color: theme.grey[600],
                        size: 20,
                      ),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.all(6),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, 20 + mediaQuery.padding.bottom),
                  child: _buildHowToReadContent(context, theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHowToReadContent(BuildContext context, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview section
        _buildSection(
          context,
          theme,
          AppLocalizations.of(context)
              .translate('trigger-radar-overview-title'),
          AppLocalizations.of(context).translate('trigger-radar-overview-text'),
          LucideIcons.info,
        ),

        verticalSpace(Spacing.points24),

        // Visual example section
        Text(
          AppLocalizations.of(context).translate('visual-example'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points12),

        // Mini radar chart example
        _buildExampleRadarChart(context, theme),

        verticalSpace(Spacing.points16),

        // Scale explanation
        _buildSection(
          context,
          theme,
          AppLocalizations.of(context).translate('understanding-scale-title'),
          AppLocalizations.of(context).translate('understanding-scale-text'),
          LucideIcons.barChart3,
        ),

        verticalSpace(Spacing.points16),

        // Scale examples with visual indicators
        _buildScaleExamples(context, theme),

        verticalSpace(Spacing.points24),

        // Reading tips
        _buildSection(
          context,
          theme,
          AppLocalizations.of(context).translate('reading-tips-title'),
          AppLocalizations.of(context).translate('reading-tips-text'),
          LucideIcons.lightbulb,
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, dynamic theme, String title,
      String text, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.primary[600],
                size: 20,
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.bodyLarge.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            text,
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleRadarChart(BuildContext context, dynamic theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary[200]!, width: 1),
      ),
      child: Column(
        children: [
          // Radar chart visualization that matches the actual chart
          Container(
            height: 200,
            width: 200,
            child: CustomPaint(
              size: Size(200, 200),
              painter: ExampleRadarPainter(theme),
            ),
          ),
          verticalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate('example-chart-explanation'),
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScaleExamples(BuildContext context, dynamic theme) {
    return Column(
      children: [
        _buildScaleExample(
            context,
            theme,
            '100%',
            AppLocalizations.of(context).translate('scale-100-description'),
            Color(0xFFF97316)),
        verticalSpace(Spacing.points8),
        _buildScaleExample(
            context,
            theme,
            '75%',
            AppLocalizations.of(context).translate('scale-75-description'),
            Color(0xFFF97316).withValues(alpha: 0.8)),
        verticalSpace(Spacing.points8),
        _buildScaleExample(
            context,
            theme,
            '50%',
            AppLocalizations.of(context).translate('scale-50-description'),
            Color(0xFFF97316).withValues(alpha: 0.6)),
        verticalSpace(Spacing.points8),
        _buildScaleExample(
            context,
            theme,
            '25%',
            AppLocalizations.of(context).translate('scale-25-description'),
            Color(0xFFF97316).withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _buildScaleExample(BuildContext context, dynamic theme,
      String percentage, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                percentage,
                style: TextStyles.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Text(
              description,
              style: TextStyles.small.copyWith(
                color: theme.grey[700],
              ),
            ),
          ),
        ],
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
                          AppLocalizations.of(context).translate(entry.key),
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

/// Custom painter for the example radar chart in the help modal
class ExampleRadarPainter extends CustomPainter {
  final dynamic theme;

  ExampleRadarPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final gridPaint = Paint()
      ..color = theme.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = Color(0xFFF97316).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw grid lines (circular)
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      canvas.drawCircle(center, r, gridPaint);
    }

    // Draw spokes
    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * 3.14159 / 180 - 3.14159 / 2;
      final end = Offset(
        center.dx + radius * 0.9 * math.cos(angle),
        center.dy + radius * 0.9 * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // Draw example data with trigger labels
    final dataPoints = [
      0.9, // stress - very high (top)
      0.65, // urges - medium-high (top-right)
      0.4, // anxiety - medium-low (bottom-right)
      0.35, // anger - low (bottom)
      0.55, // sadness - medium (bottom-left)
      0.75, // late-night - high (top-left)
    ];

    final triggerLabels = [
      'Stress',
      'Urges',
      'Anxiety',
      'Anger',
      'Sadness',
      'Late Night'
    ];

    final dataPath = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final angle = i * 60 * 3.14159 / 180 - 3.14159 / 2;
      final r = radius * dataPoints[i] * 0.9;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    // Draw filled area
    canvas.drawPath(dataPath, fillPaint);
    // Draw stroke
    canvas.drawPath(dataPath, strokePaint);

    // Draw data points
    final pointPaint = Paint()
      ..color = Color(0xFFF97316)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dataPoints.length; i++) {
      final angle = i * 60 * 3.14159 / 180 - 3.14159 / 2;
      final r = radius * dataPoints[i] * 0.9;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw trigger labels around the circle
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < triggerLabels.length; i++) {
      final angle = i * 60 * 3.14159 / 180 - 3.14159 / 2;
      final labelRadius = radius + 20;
      final labelPos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      labelPainter.text = TextSpan(
        text: triggerLabels[i],
        style: TextStyle(
          color: theme.grey[700],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      labelPainter.layout();

      // Center the text around the position
      final offset = Offset(
        labelPos.dx - labelPainter.width / 2,
        labelPos.dy - labelPainter.height / 2,
      );
      labelPainter.paint(canvas, offset);
    }

    // Draw scale labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 100% label at top
    textPainter.text = TextSpan(
      text: '100%',
      style: TextStyle(
        color: theme.grey[600],
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, 15));

    // 75% label
    textPainter.text = TextSpan(
      text: '75%',
      style: TextStyle(
        color: theme.grey[600],
        fontSize: 8,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
            center.dx - textPainter.width / 2, center.dy - radius * 0.75 + 5));

    // 50% label
    textPainter.text = TextSpan(
      text: '50%',
      style: TextStyle(
        color: theme.grey[600],
        fontSize: 8,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
            center.dx - textPainter.width / 2, center.dy - radius * 0.5 + 5));

    // 25% label
    textPainter.text = TextSpan(
      text: '25%',
      style: TextStyle(
        color: theme.grey[600],
        fontSize: 8,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
            center.dx - textPainter.width / 2, center.dy - radius * 0.25 + 5));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
