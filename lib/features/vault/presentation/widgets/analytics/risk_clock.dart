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
import 'dart:math' as math;

class RiskClock extends ConsumerWidget {
  const RiskClock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final riskDataAsync = ref.watch(riskClockDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risk clock content
        riskDataAsync.when(
          data: (hourlyData) {
            final totalEvents = hourlyData.fold(0, (sum, count) => sum + count);
            if (totalEvents < 3) {
              return _buildEmptyState(context, theme);
            }
            return _buildRiskClock(context, theme, hourlyData);
          },
          loading: () => Center(child: Spinner()),
          error: (_, __) => _buildEmptyState(context, theme),
        ),
      ],
    );
  }

  Widget _buildRiskClock(
      BuildContext context, dynamic theme, List<int> hourlyData) {
    final maxCount =
        hourlyData.fold(1, (max, count) => count > max ? count : max);
    final highestRiskHour = hourlyData.indexOf(maxCount);

    return Column(
      children: [
        // Circular chart
        AspectRatio(
          aspectRatio: 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Clock background
              CustomPaint(
                size: Size.infinite,
                painter: ClockBackgroundPainter(theme: theme),
              ),
              // Risk data
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 80,
                  sections: _generateSections(theme, hourlyData, maxCount),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is FlTapUpEvent && pieTouchResponse != null) {
                        final touchedIndex = pieTouchResponse
                            .touchedSection?.touchedSectionIndex;
                        if (touchedIndex != null &&
                            touchedIndex >= 0 &&
                            touchedIndex < 24) {
                          HapticFeedback.lightImpact();
                          _showHourDetails(
                              context, touchedIndex, hourlyData[touchedIndex]);
                        }
                      }
                    },
                  ),
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: theme.error[500],
                    size: 24,
                  ),
                  verticalSpace(Spacing.points8),
                  Text(
                    AppLocalizations.of(context)
                        .translate('highest-risk-hour')
                        .replaceAll('{hour}', _formatHour(highestRiskHour)),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points20),
        // Risk tip
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
                  AppLocalizations.of(context).translate('risk-hour-tip'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points12),
        // Enable alerts CTA
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Navigate to alerts settings
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primary[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.bellPlus,
                  color: theme.grey[50],
                  size: 20,
                ),
                horizontalSpace(Spacing.points12),
                Text(
                  AppLocalizations.of(context).translate('enable-risk-alert'),
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[50],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections(
      dynamic theme, List<int> hourlyData, int maxCount) {
    return List.generate(24, (hour) {
      final count = hourlyData[hour];
      final percentage = count / maxCount;
      final isHighRisk = count == maxCount;

      return PieChartSectionData(
        value: 1, // Equal sections for each hour
        color: _getRiskColor(theme, percentage, isHighRisk),
        radius: 40 + (percentage * 20), // Dynamic radius based on risk
        showTitle: false,
      );
    });
  }

  Color _getRiskColor(dynamic theme, double percentage, bool isHighRisk) {
    if (isHighRisk) {
      return theme.error[600]!;
    } else if (percentage > 0.7) {
      return theme.error[400]!;
    } else if (percentage > 0.4) {
      return theme.warn[400]!;
    } else if (percentage > 0) {
      return theme.warn[200]!;
    } else {
      return theme.grey[200]!;
    }
  }

  Widget _buildEmptyState(BuildContext context, dynamic theme) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clock3,
              color: theme.grey[400],
              size: 32,
            ),
            verticalSpace(Spacing.points12),
            Text(
              AppLocalizations.of(context).translate('not-enough-data'),
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

  void _showHourDetails(BuildContext context, int hour, int count) {
    final theme = AppTheme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatHour(hour),
              style: TextStyles.h4.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.bold,
              ),
            ),
            verticalSpace(Spacing.points12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.error[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count ${AppLocalizations.of(context).translate('relapses')}',
                style: TextStyles.body.copyWith(
                  color: theme.error[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            verticalSpace(Spacing.points20),
            Text(
              AppLocalizations.of(context).translate('risk-hour-tip'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

class ClockBackgroundPainter extends CustomPainter {
  final dynamic theme;

  ClockBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw hour markers
    final paint = Paint()
      ..color = theme.grey[300]!
      ..strokeWidth = 2;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 15 - 90) * math.pi / 180;
      final innerRadius = radius - 65;
      final outerRadius = radius - 55;

      final x1 = center.dx + innerRadius * math.cos(angle);
      final y1 = center.dy + innerRadius * math.sin(angle);
      final x2 = center.dx + outerRadius * math.cos(angle);
      final y2 = center.dy + outerRadius * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

      // Draw hour labels for main hours
      if (i % 6 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: i.toString(),
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final labelRadius = radius - 45;
        final labelX =
            center.dx + labelRadius * math.cos(angle) - textPainter.width / 2;
        final labelY =
            center.dy + labelRadius * math.sin(angle) - textPainter.height / 2;

        textPainter.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
