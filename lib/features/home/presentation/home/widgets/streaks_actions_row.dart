import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/streak_settings_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/simplified_reset_modal.dart';

class StreaksActionsRow extends ConsumerWidget {
  const StreaksActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Row(
      children: [
        // Customize Button
        Expanded(
          child: GestureDetector(
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
            child: WidgetsContainer(
              padding: EdgeInsets.all(12),
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.primary[300]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.settings,
                    size: 16,
                    color: theme.primary[600],
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    localization.translate("customize"),
                    style: TextStyles.footnote.copyWith(
                      color: theme.primary[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        horizontalSpace(Spacing.points8),
        // Reset Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) {
                  return SimplifiedResetModal();
                },
              );
            },
            child: WidgetsContainer(
              padding: EdgeInsets.all(12),
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.warn[300]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.refreshCw,
                    size: 16,
                    color: theme.warn[600],
                  ),
                  horizontalSpace(Spacing.points8),
                  Text(
                    localization.translate("reset-counters"),
                    style: TextStyles.footnote.copyWith(
                      color: theme.warn[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
