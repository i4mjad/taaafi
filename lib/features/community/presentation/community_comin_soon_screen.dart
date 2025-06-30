import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/community/presentation/community_feedback_modal.dart';

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
                    color: theme.primary[700],
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
                const SizedBox(height: 16),
                // Feedback button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFeedbackModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary[600],
                      foregroundColor: theme.grey[50],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(LucideIcons.messageSquare, size: 20),
                    label: Text(
                      l10n.translate('share-your-ideas'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[50],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-1'),
                  LucideIcons.users,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-2'),
                  LucideIcons.trophy,
                ),
                const SizedBox(height: 16),
                // _buildFeatureItem(
                //   context,
                //   l10n.translate('community-feature-3'),
                //   LucideIcons.messageCircle,
                // ),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-4'),
                  LucideIcons.heartHandshake,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  l10n.translate('community-feature-5'),
                  LucideIcons.shieldCheck,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text, IconData icon) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      // boxShadow: Shadows.mainShadows,
      borderSide: BorderSide.none,
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.primary[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyles.footnote.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityFeedbackModal(),
    );
  }
}
