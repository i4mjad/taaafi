import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/action_modal.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_achievement_entity.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/achievement_badge_widget.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/activity_backfill_banner.dart';
import 'package:reboot_app_3/features/groups/providers/group_activity_provider.dart';
import 'package:reboot_app_3/features/groups/providers/group_achievements_provider.dart';
import 'package:reboot_app_3/features/groups/application/group_member_management_controller.dart';

/// Member profile modal
/// Sprint 4 - Feature 4.1: Enhanced Member Profiles
class MemberProfileModal extends ConsumerWidget {
  final CommunityProfileEntity profile;
  final GroupMembershipEntity? membership;
  final bool isOwnProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onEdit;
  final bool isCurrentUserAdmin;
  final bool isGroupCreator;

  const MemberProfileModal({
    super.key,
    required this.profile,
    this.membership,
    this.isOwnProfile = false,
    this.onMessage,
    this.onEdit,
    this.isCurrentUserAdmin = false,
    this.isGroupCreator = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    // Load achievements from provider if membership exists
    final achievementsAsync = membership != null
        ? ref.watch(memberAchievementsProvider((
            groupId: membership!.groupId,
            cpId: membership!.cpId,
          )))
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with action button and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left action button
                if (isOwnProfile && onEdit != null)
                  IconButton(
                    icon: Icon(
                      LucideIcons.edit,
                      color: theme.tint[600],
                    ),
                    onPressed: onEdit,
                  )
                else if (!isOwnProfile)
                  IconButton(
                    icon: Icon(
                      LucideIcons.moreHorizontal,
                      color: theme.grey[700],
                    ),
                    onPressed: () => _showMemberActions(context, ref, l10n),
                  )
                else
                  const SizedBox(width: 40),
                Text(
                  l10n.translate('member-profile'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: theme.grey[700],
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.grey[200]),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(context, theme, l10n),

                  const SizedBox(height: 24),

                  // Activity Backfill Banner (own profile only, if activity not tracked)
                  if (isOwnProfile && membership != null) ...[
                    ActivityBackfillBanner(
                      groupId: membership!.groupId,
                      membership: membership!,
                      onBackfillComplete: () {
                        // Invalidate providers to refresh data
                        ref.invalidate(groupMembersWithActivityProvider(
                            membership!.groupId));
                        // Close modal to force reload with fresh achievements
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bio Section
                  if (profile.hasBio()) ...[
                    _buildBioSection(context, theme, l10n),
                    const SizedBox(height: 24),
                  ] else if (isOwnProfile) ...[
                    _buildEmptyBioSection(context, theme, l10n),
                    const SizedBox(height: 24),
                  ],

                  // Interests Section
                  if (profile.hasInterests()) ...[
                    _buildInterestsSection(context, theme, l10n),
                    const SizedBox(height: 24),
                  ],

                  // Achievements Section
                  _buildAchievementsSection(
                      context, theme, l10n, achievementsAsync),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.tint[100],
            border: Border.all(
              color: theme.tint[300]!,
              width: 2,
            ),
          ),
          child: profile.hasCustomAvatar()
              ? ClipOval(
                  child: Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(theme);
                    },
                  ),
                )
              : _buildDefaultAvatar(theme),
        ),

        const SizedBox(height: 12),

        // Name
        Text(
          profile.getDisplayName(),
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Role badge
        if (membership != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: membership!.role == 'admin'
                  ? theme.tint[100]
                  : theme.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              membership!.role == 'admin' ? 'Admin' : 'Member',
              style: TextStyles.caption.copyWith(
                color: membership!.role == 'admin'
                    ? theme.tint[700]
                    : theme.grey[700],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Join date and stats inline (clickable to show explanation)
        if (membership != null)
          GestureDetector(
            onTap: () => _showStatsExplanation(context, theme, l10n),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    // Join date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: theme.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatJoinDate(membership!.joinedAt, l10n),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                          ),
                        ),
                      ],
                    ),

                    // Dot separator
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),

                    // Messages count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 14,
                          color: theme.primary[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${membership!.messageCount}',
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Dot separator
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),

                    // Days active
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: theme.success[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_calculateDaysActive()}${l10n.translate('days_short')}',
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Dot separator
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),

                    // Engagement score
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.trendingUp,
                          size: 14,
                          color: theme.warn[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${membership!.engagementScore}',
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showStatsExplanation(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(LucideIcons.info, size: 20, color: theme.tint[600]),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('member-stats-explained'),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Join date explanation
            _buildStatExplanationRow(
              context,
              theme,
              l10n,
              LucideIcons.calendar,
              theme.grey[500]!,
              l10n.translate('joined-date'),
              l10n.translate('joined-date-explanation'),
            ),

            const SizedBox(height: 12),

            // Messages explanation
            _buildStatExplanationRow(
              context,
              theme,
              l10n,
              LucideIcons.messageCircle,
              theme.primary[500]!,
              l10n.translate('messages-sent'),
              l10n.translate('messages-sent-explanation'),
            ),

            const SizedBox(height: 12),

            // Days active explanation
            _buildStatExplanationRow(
              context,
              theme,
              l10n,
              LucideIcons.clock,
              theme.success[500]!,
              l10n.translate('days-active'),
              l10n.translate('days-active-explanation'),
            ),

            const SizedBox(height: 12),

            // Engagement explanation
            _buildStatExplanationRow(
              context,
              theme,
              l10n,
              LucideIcons.trendingUp,
              theme.warn[500]!,
              l10n.translate('engagement-score'),
              l10n.translate('engagement-score-explanation'),
            ),

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.translate('close'),
                  style: TextStyles.footnoteSelected,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatExplanationRow(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    IconData icon,
    Color iconColor,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
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
      ],
    );
  }

  Widget _buildDefaultAvatar(dynamic theme) {
    return Center(
      child: Icon(
        LucideIcons.user,
        size: 36,
        color: theme.tint[600],
      ),
    );
  }

  Widget _buildBioSection(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('group-bio'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            profile.groupBio!,
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyBioSection(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.fileText,
            size: 32,
            color: theme.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('add-bio'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('interests'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profile.interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.tint[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.tint[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                l10n.translate('interest-$interest'),
                style: TextStyles.caption.copyWith(
                  color: theme.tint[700],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    AsyncValue<List<GroupAchievementEntity>>? achievementsAsync,
  ) {
    final allTypes = [
      'welcome',
      'first_message',
      'week_warrior',
      'month_master',
      'helpful',
      'top_contributor',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('achievements'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        const SizedBox(height: 12),

        // Handle async achievements loading
        if (achievementsAsync == null)
          // No membership - show empty state
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.translate('no-achievements-yet'),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          achievementsAsync.when(
            data: (achievements) {
              final earnedTypes =
                  achievements.map((a) => a.achievementType).toSet();

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: allTypes.map((type) {
                  final isEarned = earnedTypes.contains(type);
                  final achievement = achievements.firstWhere(
                    (a) => a.achievementType == type,
                    orElse: () => GroupAchievementEntity(
                      id: '',
                      groupId: '',
                      cpId: profile.id,
                      achievementType: type,
                      title: '$type-achievement',
                      description: '$type-desc',
                      earnedAt: DateTime.now(),
                    ),
                  );

                  return AchievementBadgeWidget(
                    achievementType: type,
                    isEarned: isEarned,
                    earnedAt: isEarned ? achievement.earnedAt : null,
                    onTap: () => showAchievementDetails(
                      context: context,
                      achievementType: type,
                      title: '$type-achievement',
                      description: '$type-desc',
                      isEarned: isEarned,
                      earnedAt: isEarned ? achievement.earnedAt : null,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(color: theme.tint[600]),
              ),
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.error[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.translate('error-loading-achievements'),
                style: TextStyles.caption.copyWith(
                  color: theme.error[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _formatJoinDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.translate('joined-today');
    } else if (difference.inDays == 1) {
      return l10n.translate('joined-yesterday');
    } else if (difference.inDays < 30) {
      return l10n
          .translate('joined-days-ago')
          .replaceAll('{days}', '${difference.inDays}');
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return l10n
          .translate('joined-months-ago')
          .replaceAll('{months}', '$months');
    } else {
      return l10n
          .translate('joined-on-date')
          .replaceAll('{date}', '${date.day}/${date.month}/${date.year}');
    }
  }

  int _calculateDaysActive() {
    if (membership == null) return 0;
    final now = DateTime.now();
    return now.difference(membership!.joinedAt).inDays;
  }

  /// Show member action menu with appropriate options based on role and relationship
  void _showMemberActions(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (membership == null) return;

    final actions = <ActionItem>[];

    // Message action - always available for non-own profiles
    if (onMessage != null) {
      actions.add(ActionItem(
        icon: LucideIcons.messageCircle,
        title: l10n.translate('message'),
        subtitle: l10n.translate('send-direct-message'),
        onTap: () {
          Navigator.of(context).pop();
          onMessage?.call();
        },
      ));
    }

    // Report action - always available for non-own profiles
    actions.add(ActionItem(
      icon: LucideIcons.flag,
      title: l10n.translate('report-user'),
      subtitle: l10n.translate('report-inappropriate-behavior'),
      onTap: () => _reportUser(context, ref, l10n),
    ));

    // Admin-only actions
    if (isCurrentUserAdmin && !isGroupCreator) {
      // Promote/Demote action
      if (membership!.role == 'admin') {
        actions.add(ActionItem(
          icon: LucideIcons.userMinus,
          title: l10n.translate('demote-to-member'),
          subtitle: l10n.translate('remove-admin-privileges'),
          onTap: () => _demoteToMember(context, ref, l10n),
        ));
      } else {
        actions.add(ActionItem(
          icon: LucideIcons.userPlus,
          title: l10n.translate('promote-to-admin'),
          subtitle: l10n.translate('grant-admin-privileges'),
          onTap: () => _promoteToAdmin(context, ref, l10n),
        ));
      }

      // Remove from group action
      actions.add(ActionItem(
        icon: LucideIcons.userX,
        title: l10n.translate('remove-from-group'),
        subtitle: l10n.translate('permanently-remove-member'),
        isDestructive: true,
        onTap: () => _removeMember(context, ref, l10n),
      ));
    }

    ActionModal.show(context, actions: actions);
  }

  void _reportUser(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final actions = <ActionItem>[
      ActionItem(
        icon: LucideIcons.alertTriangle,
        title: l10n.translate('report-inappropriate-content'),
        onTap: () =>
            _submitUserReport(context, ref, l10n, 'inappropriate-content'),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.userMinus,
        title: l10n.translate('report-harassment'),
        onTap: () => _submitUserReport(context, ref, l10n, 'harassment'),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.shield,
        title: l10n.translate('report-spam'),
        onTap: () => _submitUserReport(context, ref, l10n, 'spam'),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.frown,
        title: l10n.translate('report-hate-speech'),
        onTap: () => _submitUserReport(context, ref, l10n, 'hate-speech'),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.moreHorizontal,
        title: l10n.translate('report-other-reason'),
        onTap: () => _submitUserReport(context, ref, l10n, 'other'),
        isDestructive: true,
      ),
    ];

    ActionModal.show(context,
        actions: actions, title: l10n.translate('report-reason'));
  }

  Future<void> _submitUserReport(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String reportTypeId,
  ) async {
    if (membership == null || !context.mounted) return;

    final navigator = Navigator.of(context);

    try {
      // Close the action modal
      navigator.pop();

      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.reportUser(
        reportedUserCpId: membership!.cpId,
        reportMessage: l10n.translate('inappropriate-behavior-in-group'),
      );

      if (!context.mounted) return;

      if (result.success) {
        getSuccessSnackBar(context, 'report-submitted-successfully');
      } else {
        getErrorSnackBar(
            context, result.errorKey ?? 'report-submission-failed');
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'report-submission-failed');
      }
    }
  }

  Future<void> _promoteToAdmin(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (membership == null || !context.mounted) return;

    try {
      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.promoteMemberToAdmin(
        groupId: membership!.groupId,
        memberCpId: membership!.cpId,
      );

      if (!context.mounted) return;

      if (result.success) {
        getSuccessSnackBar(context, 'member-promoted-successfully');
        Navigator.of(context).pop(); // Close the modal
      } else {
        getErrorSnackBar(
            context, result.errorKey ?? 'failed-to-promote-member');
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'failed-to-promote-member');
      }
    }
  }

  Future<void> _demoteToMember(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (membership == null || !context.mounted) return;

    try {
      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.demoteMemberToMember(
        groupId: membership!.groupId,
        memberCpId: membership!.cpId,
      );

      if (!context.mounted) return;

      if (result.success) {
        getSuccessSnackBar(context, 'member-demoted-successfully');
        Navigator.of(context).pop(); // Close the modal
      } else {
        getErrorSnackBar(context, result.errorKey ?? 'failed-to-demote-member');
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'failed-to-demote-member');
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (membership == null || !context.mounted) return;

    try {
      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.removeMemberFromGroup(
        groupId: membership!.groupId,
        memberCpId: membership!.cpId,
      );

      if (!context.mounted) return;

      if (result.success) {
        getSuccessSnackBar(context, 'member-removed-successfully');
        Navigator.of(context).pop(); // Close the modal
      } else {
        getErrorSnackBar(context, result.errorKey ?? 'failed-to-remove-member');
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'failed-to-remove-member');
      }
    }
  }
}

/// Show member profile modal
void showMemberProfileModal({
  required BuildContext context,
  required CommunityProfileEntity profile,
  GroupMembershipEntity? membership,
  bool isOwnProfile = false,
  VoidCallback? onMessage,
  VoidCallback? onEdit,
  bool isCurrentUserAdmin = false,
  bool isGroupCreator = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MemberProfileModal(
      profile: profile,
      membership: membership,
      isOwnProfile: isOwnProfile,
      onMessage: onMessage,
      onEdit: onEdit,
      isCurrentUserAdmin: isCurrentUserAdmin,
      isGroupCreator: isGroupCreator,
    ),
  );
}
