import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';

class VerificationCompleteWidget extends ConsumerWidget {
  const VerificationCompleteWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      backgroundColor: theme.success[50],
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.success[200]!,
        width: 2,
      ),
      cornerSmoothing: 1,
      child: Column(
        children: [
          // Celebration emoji
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            l10n.translate('referral.checklist.celebration_title'),
            style: TextStyles.h4.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            l10n.translate('referral.checklist.celebration_message'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Reward info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.success[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.gift,
                  color: theme.success[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.translate('referral.checklist.premium_reward'),
                    style: TextStyles.body.copyWith(
                      color: theme.success[900],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to Ta3afi Plus features
                context.pushNamed(RouteNames.ta3afiPlus.name);
              },
              icon: const Icon(LucideIcons.sparkles),
              label: Text(
                l10n.translate('referral.checklist.explore_premium'),
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.success[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Info text
          Text(
            l10n.translate('referral.checklist.referrer_notified'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

