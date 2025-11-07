import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_activity_provider.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

/// Activity Insights Screen - Sprint 2, Feature 2.1
/// Shows comprehensive activity statistics for group admins
class GroupActivityInsightsScreen extends ConsumerWidget {
  final String groupId;

  const GroupActivityInsightsScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final statsAsync = ref.watch(groupActivityStatsProvider(groupId));
    final membersAsync = ref.watch(membersSortedByActivityProvider(groupId));
    final inactiveMembersAsync = ref.watch(inactiveGroupMembersProvider(groupId));

    return Scaffold(
      backgroundColor: theme.grey[50],
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.grey[900]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.translate('activity-insights'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
      ),
      body: statsAsync.when(
        loading: () => Center(child: Spinner()),
        error: (error, _) => _buildErrorState(theme, l10n),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              _buildOverviewCards(stats, theme, l10n),

              verticalSpace(Spacing.points24),

              // Inactive Members Warning (if any)
              inactiveMembersAsync.when(
                data: (inactiveMembers) {
                  if (inactiveMembers.isNotEmpty) {
                    return Column(
                      children: [
                        _buildInactiveWarning(
                            inactiveMembers.length, theme, l10n),
                        verticalSpace(Spacing.points24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Members Activity List
              Text(
                l10n.translate('member-activity'),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),

              verticalSpace(Spacing.points12),

              membersAsync.when(
                loading: () => WidgetsContainer(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Spinner()),
                ),
                error: (error, _) => _buildErrorState(theme, l10n),
                data: (members) => _buildMembersList(members, theme, l10n, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(
      dynamic stats, dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('activity-overview'),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.users,
                  value: '${stats.activeMembers}',
                  label: l10n.translate('active-members'),
                  color: theme.success[500]!,
                  theme: theme,
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.userX,
                  value: '${stats.inactiveMembers}',
                  label: l10n.translate('inactive-members'),
                  color: theme.error[500]!,
                  theme: theme,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.trendingUp,
                  value: '${stats.averageEngagement}',
                  label: l10n.translate('average-engagement'),
                  color: theme.primary[500]!,
                  theme: theme,
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.award,
                  value: '${stats.mostActiveMemberScore}',
                  label: l10n.translate('most-active-member'),
                  color: theme.warning[500]!,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required dynamic theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          verticalSpace(Spacing.points12),
          Text(
            value,
            style: TextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          verticalSpace(Spacing.points4),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveWarning(
      int count, dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.warning[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.alertTriangle,
              color: theme.warning[600],
              size: 24,
            ),
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Text(
              l10n
                  .translate('inactive-warning')
                  .replaceAll('{count}', '$count'),
              style: TextStyles.body.copyWith(
                color: theme.warning[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<GroupMembershipEntity> members, dynamic theme,
      AppLocalizations l10n, WidgetRef ref) {
    if (members.isEmpty) {
      return WidgetsContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.users, size: 48, color: theme.grey[400]),
              verticalSpace(Spacing.points16),
              Text(
                l10n.translate('no-members-found'),
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return WidgetsContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < members.length; i++) ...[
            _buildMemberActivityItem(members[i], theme, l10n, ref),
            if (i < members.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.grey[200],
                indent: 72,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberActivityItem(GroupMembershipEntity member, dynamic theme,
      AppLocalizations l10n, WidgetRef ref) {
    final profileAsync = ref.watch(communityProfileByIdProvider(member.cpId));

    return profileAsync.when(
      loading: () => _buildLoadingMemberItem(theme),
      error: (_, __) => _buildErrorMemberItem(theme, l10n),
      data: (profile) {
        if (profile == null) return _buildErrorMemberItem(theme, l10n);

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with activity indicator
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: profile.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profile.avatarUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                LucideIcons.user,
                                color: theme.grey[600],
                                size: 24,
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.user,
                            color: theme.grey[600],
                            size: 24,
                          ),
                  ),
                  if (member.lastActiveAt != null &&
                      DateTime.now().difference(member.lastActiveAt!).inHours <
                          24)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.success[500],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              horizontalSpace(Spacing.points12),

              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.getDisplayNameWithPipeline(),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    verticalSpace(Spacing.points4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 12,
                          color: theme.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.messageCount} ${l10n.translate('message-count')}',
                          style: TextStyles.small.copyWith(
                            color: theme.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.trendingUp,
                          size: 12,
                          color: theme.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.engagementScore}',
                          style: TextStyles.small.copyWith(
                            color: theme.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Last active
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getEngagementLabel(member.engagementLevel, l10n),
                    style: TextStyles.small.copyWith(
                      color: _getEngagementColor(member.engagementLevel, theme),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    member.lastActiveAt != null
                        ? _formatLastActive(member.lastActiveAt!, l10n)
                        : l10n.translate('never-active'),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingMemberItem(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                verticalSpace(Spacing.points4),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMemberItem(dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        l10n.translate('error-loading-member'),
        style: TextStyles.caption.copyWith(color: theme.error[600]),
      ),
    );
  }

  Widget _buildErrorState(dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: theme.error[500]),
            verticalSpace(Spacing.points16),
            Text(
              l10n.translate('error-loading-activity-data'),
              style: TextStyles.body.copyWith(color: theme.error[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastActive(DateTime lastActive, AppLocalizations l10n) {
    final difference = DateTime.now().difference(lastActive);

    if (difference.inMinutes < 5) {
      return l10n.translate('active-now');
    } else if (difference.inHours < 1) {
      return l10n
          .translate('active-minutes-ago')
          .replaceAll('{minutes}', '${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return l10n
          .translate('active-hours-ago')
          .replaceAll('{hours}', '${difference.inHours}');
    } else if (difference.inDays < 7) {
      return l10n
          .translate('active-days-ago')
          .replaceAll('{days}', '${difference.inDays}');
    } else {
      final weeks = (difference.inDays / 7).floor();
      return l10n.translate('active-weeks-ago').replaceAll('{weeks}', '$weeks');
    }
  }

  String _getEngagementLabel(String level, AppLocalizations l10n) {
    switch (level) {
      case 'high':
        return l10n.translate('high-engagement');
      case 'medium':
        return l10n.translate('medium-engagement');
      case 'low':
      default:
        return l10n.translate('low-engagement');
    }
  }

  Color _getEngagementColor(String level, dynamic theme) {
    switch (level) {
      case 'high':
        return theme.success[600]!;
      case 'medium':
        return theme.warning[600]!;
      case 'low':
      default:
        return theme.grey[600]!;
    }
  }
}

