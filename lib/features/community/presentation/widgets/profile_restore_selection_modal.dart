import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';

import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/domain/entities/profile_statistics.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';

/// Profile restoration modal with radio button selection
class ProfileRestoreSelectionModal extends ConsumerStatefulWidget {
  const ProfileRestoreSelectionModal({super.key});

  @override
  ConsumerState<ProfileRestoreSelectionModal> createState() =>
      _ProfileRestoreSelectionModalState();
}

class _ProfileRestoreSelectionModalState
    extends ConsumerState<ProfileRestoreSelectionModal> {
  String? _selectedProfileId;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
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

                  return _buildProfileSelection(
                      context, theme, l10n, profiles, hasPlus);
                },
              ),
            ),

            // Bottom action button
            _buildBottomAction(context, theme, l10n, hasPlus),
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
                LucideIcons.refreshCw,
                color: hasPlus ? Color(0xFFFEBA01) : theme.primary[600],
                size: 24,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  l10n.translate('restore-community-profile'),
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
                        Ta3afiPlatformIcons.plus_icon,
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
                : l10n.translate('select-profile-latest-only-or-upgrade'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
          if (!hasPlus) ...[
            verticalSpace(Spacing.points8),
            GestureDetector(
              onTap: () => _showPlusPromotion(context),
              child: Text(
                l10n.translate('upgrade-to-unlock-all-profiles'),
                style: TextStyles.body.copyWith(
                  color: Color(0xFFFEBA01),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileSelection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    List<CommunityProfileEntity> profiles,
    bool hasPlus,
  ) {
    // Convert profiles to radio options
    final options = profiles.asMap().entries.map((entry) {
      final index = entry.key;
      final profile = entry.value;
      final isLatest = index == 0;
      final isAccessible = hasPlus || isLatest;

      return ProfileRadioOption(
        value: profile.id,
        profile: profile,
        isLatest: isLatest,
        isAccessible: isAccessible,
        hasPlus: hasPlus,
      );
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('available-profiles'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          verticalSpace(Spacing.points16),

          // Profile selection with radio buttons
          ...options
              .map((option) =>
                  _buildProfileRadioTile(context, theme, l10n, option))
              .toList(),

          verticalSpace(Spacing.points24),
        ],
      ),
    );
  }

  Widget _buildProfileRadioTile(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    ProfileRadioOption option,
  ) {
    return FutureBuilder<ProfileStatistics>(
      future: ref
          .read(communityServiceProvider)
          .getProfileStatistics(option.profile.id),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: WidgetsContainer(
            padding: EdgeInsets.all(16),
            backgroundColor:
                option.isAccessible ? theme.backgroundColor : theme.grey[50],
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _getCardBorderColor(theme, option),
              width: option.isLatest ? 2 : 1,
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    // Radio button
                    Opacity(
                      opacity: option.isAccessible ? 1.0 : 0.5,
                      child: Radio<String>(
                        value: option.profile.id,
                        groupValue: _selectedProfileId,
                        onChanged: option.isAccessible
                            ? (value) =>
                                setState(() => _selectedProfileId = value)
                            : null,
                        activeColor: option.hasPlus
                            ? Color(0xFFFEBA01)
                            : theme.primary[600],
                      ),
                    ),

                    horizontalSpace(Spacing.points12),

                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: option.profile.avatarUrl != null
                          ? NetworkImage(option.profile.avatarUrl!)
                          : null,
                      backgroundColor: theme.grey[200],
                      child: option.profile.avatarUrl == null
                          ? Icon(
                              LucideIcons.user,
                              color: theme.grey[600],
                              size: 16,
                            )
                          : null,
                    ),

                    horizontalSpace(Spacing.points12),

                    // Profile info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.profile.displayName,
                                  style: TextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: option.isAccessible
                                        ? theme.grey[900]
                                        : theme.grey[600],
                                  ),
                                ),
                              ),
                              if (option.isLatest)
                                _buildLatestBadge(theme, l10n),
                            ],
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            l10n.translate('created-on') +
                                ' ${_formatDate(option.profile.createdAt, l10n)}',
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                            ),
                          ),
                          if (stats?.deletedAt != null)
                            Text(
                              l10n.translate('deleted-on') +
                                  ' ${_formatDate(stats!.deletedAt!, l10n)}',
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[500],
                              ),
                            ),
                          if (stats != null && option.isAccessible) ...[
                            verticalSpace(Spacing.points8),
                            _buildStatsRow(theme, l10n, stats),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Plus required overlay
                if (!option.isAccessible)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.grey[100]?.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.lock,
                              color: Color(0xFFFEBA01),
                              size: 16,
                            ),
                            horizontalSpace(Spacing.points4),
                            Text(
                              l10n.translate('plus-required'),
                              style: TextStyles.caption.copyWith(
                                color: Color(0xFFFEBA01),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  Widget _buildStatsRow(
    CustomThemeData theme,
    AppLocalizations l10n,
    ProfileStatistics stats,
  ) {
    return Row(
      children: [
        _buildStatChip(
            theme, l10n, '${stats.postCount}', l10n.translate('posts')),
        horizontalSpace(Spacing.points8),
        _buildStatChip(
            theme, l10n, '${stats.commentCount}', l10n.translate('comments')),
        horizontalSpace(Spacing.points8),
        _buildStatChip(
            theme, l10n, '${stats.activeDays}', l10n.translate('days')),
      ],
    );
  }

  Widget _buildStatChip(
    CustomThemeData theme,
    AppLocalizations l10n,
    String value,
    String label,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value $label',
        style: TextStyles.small.copyWith(
          color: theme.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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

  Color _getCardBorderColor(CustomThemeData theme, ProfileRadioOption option) {
    if (!option.isAccessible) return theme.grey[300]!;
    if (option.isLatest) return theme.primary[400]!;
    if (option.hasPlus) return Color(0xFFFEBA01);
    return theme.grey[200]!;
  }

  Widget _buildBottomAction(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    bool hasPlus,
  ) {
    final isButtonEnabled = _selectedProfileId != null && !_isRestoring;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          top: BorderSide(color: theme.grey[200]!, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isButtonEnabled
              ? () => _restoreSelectedProfile(context, hasPlus)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasPlus ? Color(0xFFFEBA01) : theme.primary[600],
            disabledBackgroundColor: theme.grey[300],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isRestoring
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  l10n.translate('restore-selected-profile'),
                  style: TextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
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

  void _restoreSelectedProfile(BuildContext context, bool hasPlus) async {
    if (_selectedProfileId == null || _isRestoring) {
      return;
    }

    setState(() {
      _isRestoring = true;
    });

    try {
      final service = ref.read(communityServiceProvider);

      await service.restoreProfile(_selectedProfileId!,
          bypassLatestCheck: hasPlus, userHasPlusSubscription: hasPlus);

      if (mounted) {
        // Refresh all community-related providers
        ref.refresh(hasCommunityProfileProvider);

        ref.refresh(hasGroupsProfileProvider);

        ref.refresh(currentCommunityProfileProvider);

        // Refresh user profile provider to update user profile screen
        ref.invalidate(userProfileNotifierProvider);

        // Notify community screen state that a profile is now available
        ref.read(communityScreenStateProvider.notifier).refresh();

        // Close modal and show success
        Navigator.of(context).pop();

        // Navigate to main community screen (similar to after profile creation)
        context.goNamed(RouteNames.community.name);

        getSuccessSnackBar(context, 'profile-restored-successfully');
      } else {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });

        getErrorSnackBar(context, 'profile-restore-failed');
      } else {}
    }
  }

  void _showPlusPromotion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaaafiPlusSubscriptionScreen(),
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

class ProfileRadioOption {
  final String value;
  final CommunityProfileEntity profile;
  final bool isLatest;
  final bool isAccessible;
  final bool hasPlus;

  const ProfileRadioOption({
    required this.value,
    required this.profile,
    required this.isLatest,
    required this.isAccessible,
    required this.hasPlus,
  });
}
