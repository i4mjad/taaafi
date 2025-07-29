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

class GroupsOnboardingScreen extends ConsumerWidget {
  const GroupsOnboardingScreen({super.key});

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
                l10n.translate('welcome-to-groups'),
                style: TextStyles.h3.copyWith(
                  color: theme.primary[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('groups-setup-description'),
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
                        l10n.translate('groups-setup-button'),
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
                l10n.translate('groups-features'),
                style: TextStyles.h5.copyWith(
                  color: theme.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                l10n.translate('groups-feature-1'),
                LucideIcons.users,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                l10n.translate('groups-feature-2'),
                LucideIcons.messageSquare,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                l10n.translate('groups-feature-3'),
                LucideIcons.target,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                l10n.translate('groups-feature-4'),
                LucideIcons.trophy,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                l10n.translate('groups-feature-5'),
                LucideIcons.shield,
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

  void _showProfileSetupModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityProfileSetupModal(),
    );
  }
}
