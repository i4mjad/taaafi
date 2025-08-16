import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/ios_focus_providers.dart';
import '../../data/models.dart';

/// Processes raw snapshot data into displayable metrics
class UsageMetrics {
  final int totalMinutes;
  final int pickups;
  final List<AppUsageDisplay> topApps;
  final int focusScore;

  UsageMetrics({
    required this.totalMinutes,
    required this.pickups,
    required this.topApps,
    required this.focusScore,
  });
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

/// Provider that processes snapshot data into UI-friendly metrics
final usageMetricsProvider =
    Provider.autoDispose<AsyncValue<UsageMetrics>>((ref) {
  if (Platform.isIOS) {
    final snapshot = ref.watch(iosSnapshotProvider);
    return snapshot.when(
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

          final totalMinutes =
              apps.fold<int>(0, (sum, app) => sum + app.minutes);
          final pickups = (data['pickups'] as int?) ?? 0;

          // Simple focus score calculation (higher when less usage)
          final focusScore = totalMinutes == 0
              ? 100
              : (100 - (totalMinutes / 8.0).clamp(0.0, 100.0)).round();

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
          ));
        } catch (e) {
          return AsyncValue.error(e, StackTrace.current);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (e, stack) => AsyncValue.error(e, stack),
    );
  } else {
    // Android implementation would go here
    return const AsyncValue.loading();
  }
});

/// Widget that displays real usage metrics in place of hardcoded hero card
class RealUsageMetricsCard extends ConsumerWidget {
  const RealUsageMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(usageMetricsProvider);

    return metrics.when(
      data: (data) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Focus score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getScoreColor(data.focusScore),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${data.focusScore}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Real KPIs
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Kpi(
                    label: 'Total screen time',
                    value: _formatDuration(data.totalMinutes),
                  ),
                  const SizedBox(height: 8),
                  _Kpi(
                    label: 'Focus breaks',
                    value: '${data.pickups}',
                  ),
                  const SizedBox(height: 8),
                  _Kpi(
                    label: 'Top apps',
                    value: '${data.topApps.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text('Error loading data: ${e.toString()}'),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
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

/// Widget that displays real app usage list
class RealAppUsageList extends ConsumerWidget {
  const RealAppUsageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(usageMetricsProvider);

    return metrics.when(
      data: (data) {
        if (data.topApps.isEmpty) {
          return const Center(
            child: Column(
              children: [
                Icon(Icons.apps, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No app usage data yet'),
                Text('Start monitoring to see results',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.topApps.length,
          itemBuilder: (context, index) {
            final app = data.topApps[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(app.name),
              subtitle: LinearProgressIndicator(
                value: app.percentage,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              trailing: Text(_formatDuration(app.minutes)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red),
            Text('Error: ${e.toString()}'),
          ],
        ),
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

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  const _Kpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
