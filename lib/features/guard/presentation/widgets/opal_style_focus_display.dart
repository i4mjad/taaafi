import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/ios_focus_providers.dart';
import '../../data/models.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/custom_theme_data.dart';
import '../../../../core/theming/text_styles.dart';
import '../../../../core/shared_widgets/container.dart';

/// Processes raw snapshot data into displayable metrics
class UsageMetrics {
  final int totalMinutes;
  final int pickups;
  final List<AppUsageDisplay> topApps;
  final int focusScore;
  final String updateReason;
  final DateTime lastUpdate;

  UsageMetrics({
    required this.totalMinutes,
    required this.pickups,
    required this.topApps,
    required this.focusScore,
    this.updateReason = '',
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();
}

class AppUsageDisplay {
  final String name;
  final int minutes;
  final double percentage;

  AppUsageDisplay({
    required this.name,
    required this.minutes,
    required this.percentage,
  });
}

/// Provider that processes snapshot data into UI-friendly metrics (real-time)
final usageMetricsProvider =
    Provider.autoDispose<AsyncValue<UsageMetrics>>((ref) {
  final snapshotAsync = ref.watch(realtimeSnapshotProvider);
  return snapshotAsync.when(
    data: (data) {
      try {
        final apps = (data['apps'] as List? ?? [])
            .map((app) => AppUsage(
                  app['bundle'] ?? app['pkg'] ?? '',
                  app['label'] ?? app['pkg'] ?? 'Unknown App',
                  (app['minutes'] as num?)?.toInt() ?? 0,
                ))
            .where((app) => app.minutes > 0)
            .toList();

        apps.sort((a, b) => b.minutes.compareTo(a.minutes));
        final topApps = apps.take(5).toList();

        final totalMinutes = apps.fold<int>(0, (sum, app) => sum + app.minutes);
        final pickups = (data['pickups'] as int?) ?? 0;

        // Enhanced focus score calculation
        final focusScore = _calculateFocusScore(totalMinutes, pickups);

        final displayApps = topApps.map((app) {
          final percentage =
              totalMinutes > 0 ? app.minutes / totalMinutes.toDouble() : 0.0;
          return AppUsageDisplay(
            name: app.label,
            minutes: app.minutes,
            percentage: percentage,
          );
        }).toList();

        return AsyncValue.data(UsageMetrics(
          totalMinutes: totalMinutes,
          pickups: pickups,
          topApps: displayApps,
          focusScore: focusScore,
          updateReason: data['updateReason'] as String? ?? '',
          lastUpdate: DateTime.tryParse(data['lastUpdate'] as String? ?? '') ??
              DateTime.now(),
        ));
      } catch (e) {
        return AsyncValue.error(e, StackTrace.current);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

int _calculateFocusScore(int totalMinutes, int pickups) {
  if (totalMinutes == 0 && pickups == 0) return 100;

  // More sophisticated scoring
  final timeScore =
      math.max(0, 100 - (totalMinutes / 6.0)); // 6 hours = 0 score
  final pickupScore =
      math.max(0, 100 - (pickups * 3.0)); // Each pickup reduces score

  return ((timeScore * 0.7) + (pickupScore * 0.3)).round().clamp(0, 100);
}

/// Beautiful Opal-style focus score visualization
class OpalFocusScoreCard extends ConsumerWidget {
  const OpalFocusScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final metrics = ref.watch(usageMetricsProvider);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: metrics.when(
        data: (data) => Column(
          children: [
            // If there is no data (simulator or no permission yet), show a friendly empty state
            if (data.totalMinutes == 0 &&
                data.pickups == 0 &&
                data.topApps.isEmpty)
              _EmptyHeroCard(localizations: localizations, theme: theme)
            else
              // Opal-style focus score visualization
              _OpalGemVisualization(
                score: data.focusScore,
                totalMinutes: data.totalMinutes,
              ),
            const SizedBox(height: 20),

            // Screen time display
            Text(
              _formatDuration(data.totalMinutes),
              style: TextStyles.h1.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localizations.translate('screen_time_today').toUpperCase(),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MetricItem(
                  label: localizations.translate('most_used'),
                  value:
                      data.topApps.isNotEmpty ? '${data.topApps.length}' : '0',
                  icon: Icons.apps,
                  theme: theme,
                ),
                _MetricItem(
                  label: localizations.translate('focus_score'),
                  value: '${data.focusScore}%',
                  icon: Icons.psychology,
                  theme: theme,
                ),
                _MetricItem(
                  label: localizations.translate('pickups'),
                  value: '${data.pickups}',
                  icon: Icons.touch_app,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
        loading: () => const _LoadingCard(),
        error: (e, _) => _ErrorCard(error: e.toString()),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }
}

/// Beautiful opal gem-like visualization for focus score
class _OpalGemVisualization extends StatelessWidget {
  final int score;
  final int totalMinutes;

  const _OpalGemVisualization({
    required this.score,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _OpalGemPainter(
          score: score,
          theme: theme,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyles.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              Text(
                '%',
                style: TextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the opal gem effect
class _OpalGemPainter extends CustomPainter {
  final int score;
  final CustomThemeData theme;

  _OpalGemPainter({
    required this.score,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create gradient based on score
    final colors = _getScoreGradient(score);

    // Main gradient background
    final gradient = RadialGradient(
      colors: colors,
      stops: const [0.0, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
          .createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw main circle
    canvas.drawCircle(center, radius, paint);

    // Add shimmer effect
    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(
        center - const Offset(15, 15), radius * 0.3, shimmerPaint);

    // Add border glow
    final borderPaint = Paint()
      ..color = colors.first.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  List<Color> _getScoreGradient(int score) {
    if (score >= 80) {
      return [
        const Color(0xFF10B981), // Green
        const Color(0xFF059669),
        const Color(0xFF047857),
      ];
    } else if (score >= 60) {
      return [
        const Color(0xFFF59E0B), // Orange
        const Color(0xFFD97706),
        const Color(0xFFB45309),
      ];
    } else if (score >= 40) {
      return [
        const Color(0xFFEF4444), // Red
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
      ];
    } else {
      return [
        const Color(0xFF7C3AED), // Purple (very low focus)
        const Color(0xFF6D28D9),
        const Color(0xFF5B21B6),
      ];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Metric item widget
class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final CustomThemeData theme;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyles.tiny.copyWith(
            color: theme.grey[600],
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Loading state for the focus card
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 32,
          width: 100,
          decoration: BoxDecoration(
            color: theme.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 150,
          decoration: BoxDecoration(
            color: theme.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

/// Empty hero card for simulator/empty data
class _EmptyHeroCard extends StatelessWidget {
  final AppLocalizations localizations;
  final CustomThemeData theme;

  const _EmptyHeroCard({required this.localizations, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: theme.grey[300]!),
          ),
          child: Icon(
            Icons.insights_outlined,
            size: 48,
            color: theme.grey[400],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          localizations.translate('no_app_usage_data'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          localizations.translate('start_monitoring_to_see_results'),
          style: TextStyles.caption.copyWith(
            color: theme.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Error state for the focus card
class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: theme.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          localizations.translate('error_loading_data'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Beautiful app usage list with Opal styling
class OpalAppUsageList extends ConsumerWidget {
  const OpalAppUsageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final metrics = ref.watch(usageMetricsProvider);

    return metrics.when(
      data: (data) {
        if (data.topApps.isEmpty) {
          return _EmptyState(theme: theme, localizations: localizations);
        }

        return Column(
          children: data.topApps.asMap().entries.map((entry) {
            final index = entry.key;
            final app = entry.value;
            return _AppUsageItem(
              app: app,
              rank: index + 1,
              theme: theme,
            );
          }).toList(),
        );
      },
      loading: () => _LoadingList(theme: theme),
      error: (e, _) => _ErrorCard(error: e.toString()),
    );
  }
}

/// Individual app usage item
class _AppUsageItem extends StatelessWidget {
  final AppUsageDisplay app;
  final int rank;
  final CustomThemeData theme;

  const _AppUsageItem({
    required this.app,
    required this.rank,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // App icon placeholder with rank
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
                  style: TextStyles.h6.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // App info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: app.percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getRankColor(rank),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Time display
            Text(
              _formatDuration(app.minutes),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFEF4444); // Red for #1
      case 2:
        return const Color(0xFFF59E0B); // Orange for #2
      case 3:
        return const Color(0xFF10B981); // Green for #3
      default:
        return const Color(0xFF6B7280); // Gray for others
    }
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }
}

/// Empty state for app list
class _EmptyState extends StatelessWidget {
  final CustomThemeData theme;
  final AppLocalizations localizations;

  const _EmptyState({
    required this.theme,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.apps,
            size: 48,
            color: theme.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_app_usage_data'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.translate('start_monitoring_to_see_results'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Loading state for app list
class _LoadingList extends StatelessWidget {
  final CustomThemeData theme;

  const _LoadingList({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
          3,
          (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: WidgetsContainer(
                  backgroundColor: theme.grey[100]!,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.grey[200],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.grey[200],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
    );
  }
}
