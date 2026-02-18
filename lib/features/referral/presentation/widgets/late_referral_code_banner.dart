import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../providers/referral_dashboard_provider.dart';
import 'referral_code_input_sheet.dart';

/// Banner shown to users who haven't redeemed a referral code yet
/// Only shown if:
/// 1. User hasn't redeemed any code (no referredBy field)
/// 2. Account is less than 30 days old
class LateReferralCodeBanner extends ConsumerWidget {
  const LateReferralCodeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return const SizedBox.shrink();

    // Check if user was referred
    final verificationAsync = ref.watch(userVerificationProgressProvider(userId));

    return verificationAsync.when(
      data: (verification) {
        // If user has verification document, they already redeemed a code
        if (verification != null) {
          return const SizedBox.shrink();
        }

        // Check account age
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) {
              return const SizedBox.shrink();
            }

            // Check if already referred
            if (userData['referredBy'] != null) {
              return const SizedBox.shrink();
            }

            // Check account age
            final createdAt = userData['createdAt'] as Timestamp?;
            if (createdAt == null) {
              return const SizedBox.shrink();
            }

            final accountAge = DateTime.now().difference(createdAt.toDate()).inDays;
            
            // Only show if account is less than 30 days old
            if (accountAge >= 30) {
              return const SizedBox.shrink();
            }

            // Calculate days remaining
            final daysRemaining = 30 - accountAge;

            return GestureDetector(
              onTap: () {
                ReferralCodeInputSheet.show(context, ref);
              },
              child: WidgetsContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.warn[50],
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.warn[300]!,
                  width: 2,
                ),
                cornerSmoothing: 1,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.ticket,
                      color: theme.warn[700],
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('referral.late_code.title'),
                            style: TextStyles.body.copyWith(
                              color: theme.warn[900],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n
                                .translate('referral.late_code.subtitle')
                                .replaceAll('{days}', daysRemaining.toString()),
                            style: TextStyles.caption.copyWith(
                              color: theme.warn[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: theme.warn[700],
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

