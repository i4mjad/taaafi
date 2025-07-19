import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/reset_button.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/streak_settings_sheet.dart';

class CurrentStreaksSection extends ConsumerWidget {
  const CurrentStreaksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final streaksState = ref.watch(streakNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate("current-streaks"),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return StreakSettingsSheet();
                    },
                  );
                },
                child: Text(
                  AppLocalizations.of(context).translate("customize"),
                  style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
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
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: theme.grey[400],
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: Text(
                  localization.translate("starting-date") +
                      ": " +
                      (() {
                        final firstDate = streaksState.value?.userFirstDate;
                        return firstDate != null
                            ? getDisplayDateTime(
                                firstDate, locale!.languageCode)
                            : localization.translate("not-set");
                      })(),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (streaksState != null) CurrentStreaksWidget(),
          const ResetButton(),
        ],
      ),
    );
  }
}
