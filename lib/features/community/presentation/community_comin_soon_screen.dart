import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers.dart';

class CommunityComingSoonScreen extends ConsumerWidget {
  const CommunityComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Lottie.asset(
                    'asset/illustrations/community-animation.json',
                    height: 200,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.translate('community-coming-soon'),
                  style: TextStyles.h3.copyWith(
                    color: theme.primary[500],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('community-coming-soon-description'),
                  textAlign: TextAlign.center,
                  style: TextStyles.bodyLarge.copyWith(
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.translate('community-features'),
                  style: TextStyles.h4,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-1'),
                  LucideIcons.users,
                ),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-2'),
                  LucideIcons.trophy,
                ),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-3'),
                  LucideIcons.messageSquare,
                ),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-4'),
                  LucideIcons.heart,
                ),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-5'),
                  LucideIcons.lock,
                ),
                const SizedBox(height: 32),
                Consumer(
                  builder: (context, ref, child) {
                    final hasShownInterest =
                        ref.watch(hasShownInterestProvider);

                    return hasShownInterest.when(
                      data: (hasShown) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: hasShown
                              ? null
                              : () async {
                                  final serviceAsyncValue =
                                      ref.read(communityServiceProvider);
                                  if (serviceAsyncValue.hasValue) {
                                    final wasRecorded = await serviceAsyncValue
                                        .value!
                                        .recordInterest();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            wasRecorded
                                                ? l10n.translate(
                                                    'interest_recorded_success')
                                                : l10n.translate(
                                                    'interest_already_recorded'),
                                          ),
                                          backgroundColor: wasRecorded
                                              ? theme.success[500]
                                              : theme.warn[500],
                                        ),
                                      );
                                      // Refresh the provider to update the button state
                                      ref.invalidate(hasShownInterestProvider);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasShown
                                ? theme.success[300]
                                : theme.primary[500],
                            foregroundColor:
                                hasShown ? theme.grey[50] : theme.grey[50],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            hasShown
                                ? l10n.translate('already_interested')
                                : l10n.translate('im_interested'),
                            style: TextStyles.body.copyWith(
                              color: hasShown ? theme.grey[50] : theme.grey[50],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text, IconData icon) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.primary[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyles.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
