import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/profile_choice_modal.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';

class CommunityOnboardingScreen extends ConsumerWidget {
  const CommunityOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          switch (accountStatus) {
            case AccountStatus.loading:
              return const Center(child: Spinner());
            case AccountStatus.needCompleteRegistration:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CompleteRegistrationBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needConfirmDetails:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmDetailsBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needEmailVerification:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmEmailBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.pendingDeletion:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AccountActionBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.ok:
              return _buildMainContent(context, ref, theme, l10n);
          }
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, dynamic theme,
      AppLocalizations l10n) {
    return SafeArea(
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
                l10n.translate('welcome-to-community'),
                style: TextStyles.h3.copyWith(
                  color: theme.primary[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('complete-profile-setup'),
                textAlign: TextAlign.center,
                style: TextStyles.bodyLarge.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Setup Profile button
              GestureDetector(
                onTap: () => _showProfileSetupModal(context, ref),
                child: WidgetsContainer(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  backgroundColor: theme.primary[600],
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.userPlus,
                        size: 20,
                        color: theme.grey[50],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.translate('complete-setup'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[50],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                l10n.translate('community-features'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeaturesGrid(context, theme, l10n),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    final features = [
      {
        'title': l10n.translate('community-feature-1'),
        'detail': l10n.translate('community-feature-1-detail'),
        'icon': LucideIcons.users,
        'color': theme.primary[600],
      },
      {
        'title': l10n.translate('community-feature-2'),
        'detail': l10n.translate('community-feature-2-detail'),
        'icon': LucideIcons.trophy,
        'color': theme.success[600],
      },
      {
        'title': l10n.translate('community-feature-3'),
        'detail': l10n.translate('community-feature-3-detail'),
        'icon': LucideIcons.messageCircle,
        'color': theme.error[500],
      },
      {
        'title': l10n.translate('community-feature-4'),
        'detail': l10n.translate('community-feature-4-detail'),
        'icon': LucideIcons.heartHandshake,
        'color': theme.warn[600],
      },
      {
        'title': l10n.translate('community-feature-5'),
        'detail': l10n.translate('community-feature-5-detail'),
        'icon': LucideIcons.shieldCheck,
        'color': theme.grey[600],
      },
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < features.length - 1 ? 12 : 0,
          ),
          child: _buildFeatureCard(
            context: context,
            theme: theme,
            title: feature['title'] as String,
            detail: feature['detail'] as String,
            icon: feature['icon'] as IconData,
            color: feature['color'] as Color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required dynamic theme,
    required String title,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _showFeatureDetail(context, title, detail, icon, color),
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Text(
                title,
                style: TextStyles.caption.copyWith(
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: theme.grey[900],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Chevron
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureDetail(BuildContext context, String title, String detail,
      IconData icon, Color color) {
    final theme = AppTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyles.h5.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        color: theme.grey[600],
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Detail content
                Text(
                  detail,
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('got-it'),
                      style: TextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileSetupModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileChoiceModal(),
    );
  }
}
