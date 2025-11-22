import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';

/// Banner shown to referees (referred users) to track their verification progress
/// This appears in their account screen or home screen
class RefereeVerificationBanner extends ConsumerWidget {
  const RefereeVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return const SizedBox.shrink();

    // Watch the user's verification status
    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return verificationAsync.when(
      data: (verification) {
        // Only show if user was referred (has verification document)
        if (verification == null) {
          return const SizedBox.shrink();
        }

        final entity = verification.toEntity();

        // Hide if already verified and reward claimed
        if (entity.isVerified && entity.rewardAwarded) {
          return const SizedBox.shrink();
        }

        // Determine banner style based on status
        Color backgroundColor;
        Color borderColor;
        Color textColor;
        String title;
        String subtitle;
        IconData icon;

        if (entity.isVerified && !entity.rewardAwarded) {
          // Verified but not claimed reward
          backgroundColor = theme.success[50]!;
          borderColor = theme.success[300]!;
          textColor = theme.success[900]!;
          icon = LucideIcons.gift;
          title = l10n.translate('referral.banner.reward_ready');
          subtitle = l10n.translate('referral.banner.claim_3_days');
        } else {
          // Still working on verification
          final progress = entity.completedItemsCount / entity.totalItemsCount;
          backgroundColor = theme.primary[50]!;
          borderColor = theme.primary[200]!;
          textColor = theme.primary[900]!;
          icon = LucideIcons.target;
          title = l10n
              .translate('referral.banner.progress_title')
              .replaceAll('{completed}', entity.completedItemsCount.toString())
              .replaceAll('{total}', entity.totalItemsCount.toString());
          subtitle = l10n.translate('referral.banner.complete_tasks');
        }

        return GestureDetector(
          onTap: () {
            // Navigate to THEIR OWN checklist progress (interactive)
            context.pushNamed(
              RouteNames.myVerificationProgress.name,
            );
          },
          child: WidgetsContainer(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            backgroundColor: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: borderColor,
              width: 2,
            ),
            cornerSmoothing: 1,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: textColor,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyles.caption.copyWith(
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: textColor,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

