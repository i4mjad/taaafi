import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/presentation/notifiers/streak_display_notifier.dart';

/// A widget that displays detailed streak information with time components
/// This widget supports automatically updating the seconds display every second
class DetailedStreakWidget extends ConsumerWidget {
  final DetailedStreakInfo initialInfo;
  final Color color;
  final FollowUpType type;

  const DetailedStreakWidget({
    super.key,
    required this.initialInfo,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final streakInfo = ref.watch(detailedStreakProvider);

    // Convert FollowUpType to string key
    final String typeKey = type.toString().split('.').last;

    // Check if the streak info is available
    if (!streakInfo.containsKey(typeKey) || streakInfo[typeKey] == null) {
      return Center(
        child: Spinner(
          valueColor: theme.grey[100],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TimeUnit(
              value: streakInfo[typeKey]!.months,
              label: localization.translate("months"),
              color: color,
            ),
            _TimeUnit(
              value: streakInfo[typeKey]!.days,
              label: localization.translate("days"),
              color: color,
            ),
            _TimeUnit(
              value: streakInfo[typeKey]!.hours,
              label: localization.translate("hours"),
              color: color,
            ),
            _TimeUnit(
              value: streakInfo[typeKey]!.minutes,
              label: localization.translate("minutes"),
              color: color,
            ),
            _TimeUnit(
              value: streakInfo[typeKey]!.seconds,
              label: localization.translate("seconds"),
              color: color,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyles.h6.copyWith(
            color: theme.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points4),
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: theme.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
