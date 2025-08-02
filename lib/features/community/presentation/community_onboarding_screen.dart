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
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
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

  void _showProfileSetupModal(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    // Check if user has a deleted profile that can be restored
    try {
      final service = ref.read(communityServiceProvider);
      final deletedProfileId = await service.getDeletedProfileId();

      if (deletedProfileId != null && context.mounted) {
        // Show choice modal for restoration vs fresh start
        _showRejoinChoiceModal(context, ref, deletedProfileId);
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

  void _showRejoinChoiceModal(
      BuildContext context, WidgetRef ref, String deletedProfileId) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      LucideIcons.userCheck,
                      size: 24,
                      color: theme.primary[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.translate('community-rejoin-welcome'),
                        style: TextStyles.h4.copyWith(
                          color: theme.primary[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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

    // Show loading modal
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (modalContext) => _RestoreProgressModal(
        ref: ref,
        deletedProfileId: deletedProfileId,
        l10n: l10n,
      ),
    );
  }
}

class _RestoreProgressModal extends StatefulWidget {
  final WidgetRef ref;
  final String deletedProfileId;
  final AppLocalizations l10n;

  const _RestoreProgressModal({
    required this.ref,
    required this.deletedProfileId,
    required this.l10n,
  });

  @override
  State<_RestoreProgressModal> createState() => _RestoreProgressModalState();
}

class _RestoreProgressModalState extends State<_RestoreProgressModal> {
  bool _isRestoring = true;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performRestore();
  }

  Future<void> _performRestore() async {
    try {
      final service = widget.ref.read(communityServiceProvider);
      await service.restoreProfile(widget.deletedProfileId);

      if (mounted) {
        setState(() {
          _isRestoring = false;
          _isSuccess = true;
        });

        // Refresh profile cache
        widget.ref.refresh(hasCommunityProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _isSuccess = false;
          _errorMessage = widget.l10n.translate('community-restore-failed');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          if (_isRestoring) ...[
            // Loading state
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              widget.l10n.translate('community-restore-progress'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (_isSuccess) ...[
            // Success state
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.success[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.check,
                color: theme.success[600],
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.l10n.translate('community-restore-completed'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.l10n.translate('community-profile-restored-message'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close modal
                  context.goNamed(
                      RouteNames.community.name); // Navigate to community
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.l10n.translate('community-continue'),
                  style: TextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Error state
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.error[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                color: theme.error[600],
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ??
                  widget.l10n.translate('community-restore-failed'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close modal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.l10n.translate('community-close'),
                  style: TextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
