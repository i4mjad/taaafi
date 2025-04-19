import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                Padding(
                  padding: const EdgeInsets.only(right: 32, left: 32),
                  child: Column(
                    children: [
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
                      _buildFeatureItem(
                        context,
                        l10n.translate('community-feature-5'),
                        LucideIcons.shieldCheck,
                      ),
                    ],
                  ),
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
            color: theme.primary[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyles.footnote.copyWith(
                fontSize: 20,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
