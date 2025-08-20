import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';

class GroupsMainScreen extends ConsumerWidget {
  const GroupsMainScreen({super.key});

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

  Widget _buildMainContent(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Main illustration
              Center(
                child: SvgPicture.asset(
                  'asset/illustrations/groups-main-illustration.svg',
                  height: 200,
                ),
              ),

              const SizedBox(height: 40),

              // Main title
              Text(
                l10n.translate('groups-main-title'),
                style: TextStyles.h2.copyWith(
                  color: theme.grey[900],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature items
              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-1-title'),
                l10n.translate('groups-main-feature-1-desc'),
                LucideIcons.users,
              ),

              const SizedBox(height: 24),

              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-2-title'),
                l10n.translate('groups-main-feature-2-desc'),
                LucideIcons.shield,
              ),

              const SizedBox(height: 24),

              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-3-title'),
                l10n.translate('groups-main-feature-3-desc'),
                LucideIcons.trophy,
              ),

              const SizedBox(height: 24),

              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-4-title'),
                l10n.translate('groups-main-feature-4-desc'),
                LucideIcons.layers,
              ),

              const SizedBox(height: 48),

              // Join Group button
              GestureDetector(
                onTap: () => _showJoinGroupModal(context, ref),
                child: WidgetsContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  backgroundColor: theme.primary[600],
                  borderRadius: BorderRadius.circular(10.5),
                  borderSide: BorderSide.none,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('groups-main-join-button'),
                        style: TextStyles.footnote.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Create Group button
              GestureDetector(
                onTap: () => _showCreateGroupModal(context, ref),
                child: WidgetsContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  backgroundColor: theme.primary[100],
                  borderRadius: BorderRadius.circular(10.5),
                  borderSide: BorderSide(
                    color: theme.primary[200]!,
                    width: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('groups-main-create-button'),
                        style: TextStyles.footnote.copyWith(
                          color: theme.primary[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, CustomThemeData theme,
      String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primary[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.primary[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.h5.copyWith(
                  color: theme.primary[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showJoinGroupModal(BuildContext context, WidgetRef ref) {
    // TODO: Implement join group modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join Group feature coming soon')),
    );
  }

  void _showCreateGroupModal(BuildContext context, WidgetRef ref) {
    // TODO: Implement create group modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Group feature coming soon')),
    );
  }
}
