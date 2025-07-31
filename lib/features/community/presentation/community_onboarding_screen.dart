import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/community/presentation/community_profile_setup_modal.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:go_router/go_router.dart';

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
              _buildFeatureItem(
                context,
                l10n.translate('community-feature-3'),
                LucideIcons.messageCircle,
              ),
              const SizedBox(height: 16),
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
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text, IconData icon) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
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

  void _showProfileSetupModal(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    // Check if user has a deleted profile that can be restored
    try {
      final service = ref.read(communityServiceProvider);
      final deletedProfileId = await service.getDeletedProfileId();

      if (deletedProfileId != null && context.mounted) {
        // Show choice dialog for restoration vs fresh start
        _showRejoinChoiceDialog(context, ref, deletedProfileId);
      } else if (context.mounted) {
        // Show normal profile setup
        _showNormalProfileSetup(context);
      }
    } catch (e) {
      // If error checking deleted profile, show normal setup
      if (context.mounted) {
        _showNormalProfileSetup(context);
      }
    }
  }

  void _showNormalProfileSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityProfileSetupModal(),
    );
  }

  void _showRejoinChoiceDialog(
      BuildContext context, WidgetRef ref, String deletedProfileId) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.translate('community-rejoin-welcome'),
            style: TextStyles.h4.copyWith(
              color: theme.primary[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('community-rejoin-choice'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Restore option
              _buildChoiceButton(
                context: context,
                theme: theme,
                title: l10n.translate('community-rejoin-restore'),
                description:
                    l10n.translate('community-rejoin-restore-description'),
                icon: LucideIcons.refreshCw,
                onTap: () {
                  Navigator.of(context).pop();
                  _restoreProfile(context, ref, deletedProfileId);
                },
              ),

              const SizedBox(height: 16),

              // Fresh start option
              _buildChoiceButton(
                context: context,
                theme: theme,
                title: l10n.translate('community-rejoin-fresh'),
                description:
                    l10n.translate('community-rejoin-fresh-description'),
                icon: LucideIcons.userPlus,
                onTap: () {
                  Navigator.of(context).pop();
                  _showNormalProfileSetup(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required dynamic theme,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.grey[50],
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.grey[200]!,
          width: 1,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: theme.primary[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
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

  void _restoreProfile(
      BuildContext context, WidgetRef ref, String deletedProfileId) async {
    final l10n = AppLocalizations.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(l10n.translate('community-restore-progress')),
          ],
        ),
      ),
    );

    try {
      final service = ref.read(communityServiceProvider);
      await service.restoreProfile(deletedProfileId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success and navigate to community
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('community-restore-completed')),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh profile cache and navigate
        ref.refresh(hasCommunityProfileProvider);
        context.goNamed(RouteNames.community.name);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('community-restore-failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
