import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_screen.dart';

class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (BuildContext context) {
            return const TaaafiPlusSubscriptionScreen();
          },
        );
      },
      child: WidgetsContainer(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.primary[50],
        borderSide: BorderSide(color: theme.primary[500]!),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primary[200]!.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Try Ta'aafi Plus" header button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primary[500],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                AppLocalizations.of(context).translate('try-ta3afi-plus'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[50],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            verticalSpace(Spacing.points12),

            // Trial description
            Text(
              AppLocalizations.of(context).translate('free-trial-description'),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[700],
                height: 1.3,
              ),
            ),

            verticalSpace(Spacing.points12),

            // Monthly price
            Text(
              AppLocalizations.of(context)
                  .translate('subscription-monthly-price'),
              style: TextStyles.h6.copyWith(
                color: theme.primary[800],
                fontWeight: FontWeight.bold,
              ),
            ),

            verticalSpace(Spacing.points16),

            // Continue button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.primary[500],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context).translate('continue'),
                textAlign: TextAlign.center,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[50],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
