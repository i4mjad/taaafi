import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/presentation/reset_data_modal_sheet.dart';

class ResetButton extends ConsumerWidget {
  const ResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showResetDataDialog(context, ref);
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
    );
  }

  void _showResetDataDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ResetDataModalSheet();
      },
    );
  }
}
