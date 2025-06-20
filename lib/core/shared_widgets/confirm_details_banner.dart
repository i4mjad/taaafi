import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

/// Banner that asks the user to review and confirm missing profile details.
class ConfirmDetailsBanner extends ConsumerWidget {
  const ConfirmDetailsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.error[50],
        border: Border.all(color: theme.error[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: theme.error[600], size: 24),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('confirm-details-banner'),
              style: TextStyles.footnote.copyWith(
                color: theme.error[800],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          horizontalSpace(Spacing.points12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.goNamed(RouteNames.confirmUserDetails.name);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.error[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context).translate('confirm-details'),
                style: TextStyles.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
