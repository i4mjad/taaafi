import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/community/presentation/community_profile_setup_modal.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/profile_restore_selection_modal.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

/// Profile choice options based on user's current state
enum ProfileChoiceOption {
  createOnly, // User has no profiles at all
  restoreOnly, // User has deleted profiles but no active profile
  both, // User has deleted profiles and no active profile (both options available)
  none, // User already has active profile (shouldn't show modal)
}

/// Initial choice modal for profile setup - Restore vs Create New
class ProfileChoiceModal extends ConsumerStatefulWidget {
  const ProfileChoiceModal({super.key});

  @override
  ConsumerState<ProfileChoiceModal> createState() => _ProfileChoiceModalState();
}

class _ProfileChoiceModalState extends ConsumerState<ProfileChoiceModal> {
  ProfileChoiceOption? _availableOptions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserProfileState();
  }

  Future<void> _checkUserProfileState() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final communityService = ref.read(communityServiceProvider);

      // Check if user already has an active profile
      final hasActiveProfile = await communityService.hasProfile();

      if (hasActiveProfile) {
        // User already has active profile - shouldn't show this modal
        setState(() {
          _availableOptions = ProfileChoiceOption.none;
          _isLoading = false;
        });
        return;
      }

      // Check if user has any deleted profiles to restore
      final deletedProfileId = await communityService.getDeletedProfileId();
      final hasDeletedProfiles = deletedProfileId != null;

      setState(() {
        if (hasDeletedProfiles) {
          _availableOptions =
              ProfileChoiceOption.both; // Can restore or create new
        } else {
          _availableOptions =
              ProfileChoiceOption.createOnly; // Can only create new
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Default to create only if there's an error
        _availableOptions = ProfileChoiceOption.createOnly;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return _buildLoadingModal(theme, l10n);
    }

    if (_availableOptions == ProfileChoiceOption.none) {
      // User already has active profile - close modal and refresh community state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
          // Refresh community profile providers instead of screen state
          ref.invalidate(currentCommunityProfileProvider);
        }
      });
      return _buildLoadingModal(theme, l10n);
    }

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

            // Options based on user state
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _buildOptionsForState(theme, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingModal(CustomThemeData theme, AppLocalizations l10n) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spinner(
                valueColor: theme.primary[600],
              ),
              verticalSpace(Spacing.points16),
              Text(
                l10n.translate('checking-profile-status'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsForState(CustomThemeData theme, AppLocalizations l10n) {
    final options = <Widget>[];

    switch (_availableOptions) {
      case ProfileChoiceOption.createOnly:
        options.add(
          Column(
            children: [
              verticalSpace(Spacing.points24),
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
              verticalSpace(Spacing.points16),
              Text(
                l10n.translate('no-previous-profiles-found'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        break;

      case ProfileChoiceOption.restoreOnly:
        options.add(
          Column(
            children: [
              verticalSpace(Spacing.points24),
              _buildOptionCard(
                context: context,
                theme: theme,
                l10n: l10n,
                icon: LucideIcons.refreshCw,
                title: l10n.translate('restore-previous-profile'),
                description: l10n.translate('restore-previous-profile-desc'),
                color: theme.primary[600]!,
                onTap: () => _showRestoreSelection(context),
              ),
            ],
          ),
        );
        break;

      case ProfileChoiceOption.both:
        options.add(
          Column(
            children: [
              verticalSpace(Spacing.points24),
              _buildOptionCard(
                context: context,
                theme: theme,
                l10n: l10n,
                icon: LucideIcons.refreshCw,
                title: l10n.translate('restore-previous-profile'),
                description: l10n.translate('restore-previous-profile-desc'),
                color: theme.primary[600]!,
                onTap: () => _showRestoreSelection(context),
              ),
              verticalSpace(Spacing.points16),
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
        );
        break;

      case ProfileChoiceOption.none:
      case null:
        options.add(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: theme.grey[400],
              ),
              verticalSpace(Spacing.points16),
              Text(
                l10n.translate('profile-already-exists'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        break;
    }

    return Column(children: options);
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
