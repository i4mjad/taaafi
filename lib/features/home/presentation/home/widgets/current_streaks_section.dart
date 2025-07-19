import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/streaks_actions_row.dart';

class CurrentStreaksSection extends ConsumerWidget {
  const CurrentStreaksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final streaksState = ref.watch(streakNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate("current-streaks"),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate("current-streaks-description"),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
          if (streaksState != null) CurrentStreaksWidget(),
          const StreaksActionsRow(),
        ],
      ),
    );
  }
}
