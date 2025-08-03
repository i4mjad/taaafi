import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/community/presentation/community_profile_setup_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/profile_restore_selection_modal.dart';

/// Initial choice modal for profile setup - Restore vs Create New
class ProfileChoiceModal extends ConsumerWidget {
  const ProfileChoiceModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.userPlus,
                        color: theme.primary[600],
                        size: 24,
                      ),
                      horizontalSpace(Spacing.points12),
                      Expanded(
                        child: Text(
                          l10n.translate('setup-community-profile'),
                          style: TextStyles.h4.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(Spacing.points8),
                  Text(
                    l10n.translate('choose-profile-setup-option'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    verticalSpace(Spacing.points24),

                    // Restore profile option
                    _buildOptionCard(
                      context: context,
                      theme: theme,
                      l10n: l10n,
                      icon: LucideIcons.refreshCw,
                      title: l10n.translate('restore-previous-profile'),
                      description:
                          l10n.translate('restore-previous-profile-desc'),
                      color: theme.primary[600]!,
                      onTap: () => _showRestoreSelection(context),
                    ),

                    verticalSpace(Spacing.points16),

                    // Create new option
                    _buildOptionCard(
                      context: context,
                      theme: theme,
                      l10n: l10n,
                      icon: LucideIcons.userPlus,
                      title: l10n.translate('create-new-profile'),
                      description: l10n.translate('create-new-profile-desc'),
                      color: theme.success[600]!,
                      onTap: () => _showCreateNewProfile(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        padding: EdgeInsets.all(20),
        backgroundColor: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            horizontalSpace(Spacing.points16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    description,
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreSelection(BuildContext context) {
    Navigator.of(context).pop(); // Close current modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileRestoreSelectionModal(),
    );
  }

  void _showCreateNewProfile(BuildContext context) {
    Navigator.of(context).pop(); // Close current modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityProfileSetupModal(),
    );
  }
}
