import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_achievement_entity.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/achievement_badge_widget.dart';

/// Member profile modal
/// Sprint 4 - Feature 4.1: Enhanced Member Profiles
class MemberProfileModal extends ConsumerWidget {
  final CommunityProfileEntity profile;
  final GroupMembershipEntity? membership;
  final List<GroupAchievementEntity> achievements;
  final bool isOwnProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onEdit;

  const MemberProfileModal({
    super.key,
    required this.profile,
    this.membership,
    this.achievements = const [],
    this.isOwnProfile = false,
    this.onMessage,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

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

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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

                  // Stats Section
                  if (membership != null) ...[
                    _buildStatsSection(context, theme, l10n),
                    const SizedBox(height: 24),
                  ],

                  // Achievements Section
                  _buildAchievementsSection(context, theme, l10n),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Action Buttons
          if (!isOwnProfile || onEdit != null)
            _buildActionButtons(context, theme, l10n),
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

        // Join date
        if (membership != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: theme.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _formatJoinDate(membership!.joinedAt),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                ),
              ),
            ],
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

  Widget _buildStatsSection(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('member-stats'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                theme,
                l10n,
                LucideIcons.messageCircle,
                membership!.messageCount.toString(),
                l10n.translate('messages-sent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                theme,
                l10n,
                LucideIcons.calendar,
                _calculateDaysActive().toString(),
                l10n.translate('days-active'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          theme,
          l10n,
          LucideIcons.trendingUp,
          membership!.engagementScore.toString(),
          l10n.translate('engagement-score'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            icon,
            size: 24,
            color: theme.tint[600],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.h4.copyWith(
              color: theme.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    final earnedTypes = achievements.map((a) => a.achievementType).toSet();
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
        if (achievements.isEmpty && !isOwnProfile)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.award,
                  size: 32,
                  color: theme.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('no-achievements-yet'),
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
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
          ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (isOwnProfile && onEdit != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(LucideIcons.edit, size: 18),
                  label: Text(
                    l10n.translate('edit-group-profile'),
                    style: TextStyles.footnote,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.tint[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else if (!isOwnProfile && onMessage != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onMessage,
                  icon: Icon(LucideIcons.messageCircle, size: 18),
                  label: Text(
                    'Message ${profile.displayName}',
                    style: TextStyles.footnote,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.tint[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Joined today';
    } else if (difference.inDays == 1) {
      return 'Joined yesterday';
    } else if (difference.inDays < 30) {
      return 'Joined ${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Joined $months ${months == 1 ? "month" : "months"} ago';
    } else {
      return 'Joined ${date.day}/${date.month}/${date.year}';
    }
  }

  int _calculateDaysActive() {
    if (membership == null) return 0;
    final now = DateTime.now();
    return now.difference(membership!.joinedAt).inDays;
  }
}

/// Show member profile modal
void showMemberProfileModal({
  required BuildContext context,
  required CommunityProfileEntity profile,
  GroupMembershipEntity? membership,
  List<GroupAchievementEntity> achievements = const [],
  bool isOwnProfile = false,
  VoidCallback? onMessage,
  VoidCallback? onEdit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MemberProfileModal(
      profile: profile,
      membership: membership,
      achievements: achievements,
      isOwnProfile: isOwnProfile,
      onMessage: onMessage,
      onEdit: onEdit,
    ),
  );
}

