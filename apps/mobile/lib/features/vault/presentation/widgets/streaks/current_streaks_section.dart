import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_widget.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/streaks/streaks_actions_row.dart';

class CurrentStreaksSection extends ConsumerWidget {
  const CurrentStreaksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaksState = ref.watch(streakNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (streaksState != null) ...[
          CurrentStreaksWidget(),
          verticalSpace(Spacing.points12),
        ],
        const StreaksActionsRow(),
      ],
    );
  }
}
