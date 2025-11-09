import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_blur_overlay.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/domain/entities/profile_statistics.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/community_profile_setup_modal.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:intl/intl.dart';

/// Enhanced profile selection modal that shows all deleted profiles
/// with Plus feature gating and promotion
class EnhancedProfileSelectionModal extends ConsumerStatefulWidget {
  const EnhancedProfileSelectionModal({super.key});

  @override
  ConsumerState<EnhancedProfileSelectionModal> createState() =>
      _EnhancedProfileSelectionModalState();
}

class _EnhancedProfileSelectionModalState
    extends ConsumerState<EnhancedProfileSelectionModal> {
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final themeController = ref.watch(customThemeProvider);
    final isDarkTheme = themeController.darkTheme;
    final l10n = AppLocalizations.of(context);
    final hasPlus = ref.watch(hasActiveSubscriptionProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
            _buildHeader(context, theme, l10n, hasPlus),

            // Content
            Expanded(
              child: FutureBuilder<List<CommunityProfileEntity>>(
                future:
                    ref.read(communityServiceProvider).getAllDeletedProfiles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Spinner());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(context, theme, l10n);
                  }

                  final profiles = snapshot.data ?? [];

                  if (profiles.isEmpty) {
                    return _buildEmptyState(context, theme, l10n);
                  }

                  return _buildProfilesList(
                      context, theme, l10n, profiles, hasPlus, isDarkTheme);
                },
              ),
            ),

            // Create new profile option
            _buildCreateNewOption(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, bool hasPlus) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.history,
                color: hasPlus ? Color(0xFFFEBA01) : theme.primary[600],
                size: 24,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  l10n.translate('community-profile-history'),
                  style: TextStyles.h4.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasPlus)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFEBA01), Color(0xFFFFD700)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Ta3afiPlatformIcons.plus,
                        color: Colors.white,
                        size: 12,
                      ),
                      horizontalSpace(Spacing.points4),
                      Text(
                        l10n.translate('plus-user'),
                        style: TextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            hasPlus
                ? l10n.translate('select-any-profile-to-restore')
                : l10n.translate('latest-profile-available-upgrade-for-more'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesList(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    List<CommunityProfileEntity> profiles,
    bool hasPlus,
    bool isDarkTheme,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final isLatest = index == 0;
        final isAccessible = hasPlus || isLatest;

        return FutureBuilder<ProfileStatistics>(
          future: ref
              .read(communityServiceProvider)
              .getProfileStatistics(profile.id),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data;

            return _buildProfileCard(
              context: context,
              theme: theme,
              l10n: l10n,
              profile: profile,
              statistics: stats,
              isLatest: isLatest,
              isAccessible: isAccessible,
              hasPlus: hasPlus,
              isDarkTheme: isDarkTheme,
              onTap: isAccessible
                  ? () => _restoreProfile(context, profile.id, hasPlus)
                  : () => _showPlusPromotion(context),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required CommunityProfileEntity profile,
    ProfileStatistics? statistics,
    required bool isLatest,
    required bool isAccessible,
    required bool hasPlus,
    required bool isDarkTheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isRestoring ? null : onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // Main card content
            WidgetsContainer(
              padding: EdgeInsets.all(20),
              backgroundColor: isAccessible
                  ? (hasPlus && isAccessible ? theme.grey[50] : theme.grey[50])
                  : theme.grey[100],
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    _getCardBorderColor(theme, isLatest, isAccessible, hasPlus),
                width: isLatest ? 2 : 1,
              ),
              boxShadow: isAccessible
                  ? [
                      BoxShadow(
                        color: _getCardBorderColor(
                                theme, isLatest, isAccessible, hasPlus)
                            .withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        backgroundColor: theme.grey[200],
                        child: profile.avatarUrl == null
                            ? Icon(
                                LucideIcons.user,
                                color: theme.grey[600],
                                size: 20,
                              )
                            : null,
                      ),
                      horizontalSpace(Spacing.points16),

                      // Profile info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: TextStyles.h6.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isAccessible
                                    ? theme.grey[900]
                                    : theme.grey[600],
                              ),
                            ),
                            verticalSpace(Spacing.points4),
                            Text(
                              _formatDate(profile.createdAt, l10n),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[500],
                              ),
                            ),
                            if (statistics?.deletedAt != null)
                              Text(
                                l10n.translate('deleted-on') +
                                    ' ${_formatDate(statistics!.deletedAt!, l10n)}',
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Status badges
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isLatest) _buildLatestBadge(theme, l10n),
                          if (!isAccessible && !hasPlus)
                            _buildLockedBadge(theme, l10n),
                        ],
                      ),
                    ],
                  ),

                  // Statistics section
                  if (statistics != null && isAccessible) ...[
                    verticalSpace(Spacing.points16),
                    _buildStatisticsSection(context, theme, l10n, statistics),
                  ],

                  // Plus promotion banner for locked profiles
                  if (!isAccessible) ...[
                    verticalSpace(Spacing.points16),
                    _buildPlusPromotionBanner(context, theme, l10n),
                  ],
                ],
              ),
            ),

            // Blur overlay for locked profiles
            if (!isAccessible)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PremiumBlurOverlay(
                    content: Container(height: 200),
                    isDarkTheme: isDarkTheme,
                    constraints: BoxConstraints(minHeight: 200),
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    ProfileStatistics statistics,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatItem(
            theme,
            l10n,
            LucideIcons.fileText,
            statistics.postCount.toString(),
            l10n.translate('posts'),
          ),
          Expanded(child: Container()),
          _buildStatItem(
            theme,
            l10n,
            LucideIcons.messageCircle,
            statistics.commentCount.toString(),
            l10n.translate('comments'),
          ),
          Expanded(child: Container()),
          _buildStatItem(
            theme,
            l10n,
            LucideIcons.calendar,
            statistics.activeDays.toString(),
            l10n.translate('active-days'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    CustomThemeData theme,
    AppLocalizations l10n,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.grey[600], size: 16),
        verticalSpace(Spacing.points4),
        Text(
          value,
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyles.small.copyWith(
            color: theme.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getCardBorderColor(
    CustomThemeData theme,
    bool isLatest,
    bool isAccessible,
    bool hasPlus,
  ) {
    if (!isAccessible) return theme.grey[300]!;
    if (isLatest) return theme.primary[400]!;
    if (hasPlus) return Color(0xFFFEBA01);
    return theme.grey[200]!;
  }

  Widget _buildLatestBadge(CustomThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primary[600],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        l10n.translate('latest'),
        style: TextStyles.small.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLockedBadge(CustomThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: theme.grey[500],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lock, color: Colors.white, size: 12),
          horizontalSpace(Spacing.points4),
          Text(
            l10n.translate('plus-required'),
            style: TextStyles.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlusPromotionBanner(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFEBA01), Color(0xFFFFD700)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Ta3afiPlatformIcons.plus,
            color: Colors.white,
            size: 16,
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              l10n.translate('unlock-all-profiles-with-plus'),
              style: TextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.RTL
                ? LucideIcons.arrowLeft
                : LucideIcons.arrowRight,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.userX,
            color: theme.grey[400],
            size: 48,
          ),
          verticalSpace(Spacing.points16),
          Text(
            l10n.translate('no-deleted-profiles-found'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[600],
            ),
          ),
          verticalSpace(Spacing.points8),
          Text(
            l10n.translate('no-deleted-profiles-desc'),
            style: TextStyles.body.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: theme.error[500],
            size: 48,
          ),
          verticalSpace(Spacing.points16),
          Text(
            l10n.translate('error-loading-profiles'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewOption(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          top: BorderSide(color: theme.grey[200]!, width: 1),
        ),
      ),
      child: GestureDetector(
        onTap: _isRestoring ? null : () => _showCreateNewProfile(context),
        child: WidgetsContainer(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          backgroundColor: theme.grey[100],
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.grey[300]!, width: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.userPlus,
                size: 20,
                color: theme.grey[700],
              ),
              horizontalSpace(Spacing.points8),
              Text(
                l10n.translate('create-new-profile'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restoreProfile(
      BuildContext context, String profileId, bool hasPlus) async {
    if (_isRestoring) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      final service = ref.read(communityServiceProvider);
      await service.restoreProfile(profileId,
          bypassLatestCheck: hasPlus, userHasPlusSubscription: hasPlus);

      if (mounted) {
        // Refresh profile cache
        ref.refresh(hasCommunityProfileProvider);

        // Close modal and show success
        Navigator.of(context).pop();

        getSuccessSnackBar(context, "profile-restored-successfully");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });

        getErrorSnackBar(context, "profile-restore-failed");
      }
    }
  }

  void _showPlusPromotion(BuildContext context) {
    context.pushNamed(RouteNames.plusFeaturesGuide.name);
  }

  void _showCreateNewProfile(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityProfileSetupModal(),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return l10n.translate('today');
    } else if (difference.inDays < 7) {
      return l10n
          .translate('days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n
          .translate('weeks-ago')
          .replaceAll('{weeks}', weeks.toString());
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
