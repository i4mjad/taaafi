import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/action_modal.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';

/// Model for group member with user details
class GroupMemberInfo {
  final GroupMembershipEntity membership;
  final String displayName;
  final String? avatarUrl;
  final bool isAnonymous;
  final bool isPlusUser;
  final String? gender;

  const GroupMemberInfo({
    required this.membership,
    required this.displayName,
    this.avatarUrl,
    this.isAnonymous = false,
    this.isPlusUser = false,
    this.gender,
  });
}

class GroupMemberItem extends ConsumerWidget {
  final GroupMembershipEntity membershipEntity;
  final bool isCurrentUserAdmin;
  final String currentUserCpId;

  const GroupMemberItem({
    super.key,
    required this.membershipEntity,
    required this.isCurrentUserAdmin,
    required this.currentUserCpId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    final memberProfileAsync =
        ref.watch(communityProfileByIdProvider(membershipEntity.cpId));

    return memberProfileAsync.when(
      loading: () => _buildLoadingState(theme),
      error: (error, _) => _buildErrorState(theme, l10n),
      data: (profile) {
        if (profile == null) {
          return _buildErrorState(theme, l10n);
        }

        final isCurrentUser = membershipEntity.cpId == currentUserCpId;
        final memberInfo = GroupMemberInfo(
          membership: membershipEntity,
          displayName: profile.getDisplayNameWithPipeline(),
          avatarUrl: profile.avatarUrl,
          isAnonymous: profile.isAnonymous,
          isPlusUser: profile.hasPlusSubscription(),
          gender: profile.gender,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAvatarColor(memberInfo.gender, theme),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: memberInfo.membership.role == 'admin'
                        ? theme.primary[200]!
                        : theme.grey[200]!,
                    width: 2,
                  ),
                ),
                child: memberInfo.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          memberInfo.avatarUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(theme, memberInfo),
                        ),
                      )
                    : _buildDefaultAvatar(theme, memberInfo),
              ),

              horizontalSpace(Spacing.points16),

              // Member details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and role badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getLocalizedDisplayName(
                                memberInfo.displayName, l10n),
                            style: TextStyles.footnote.copyWith(
                              color: theme.grey[900],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: memberInfo.membership.role == 'admin'
                                ? theme.primary[100]
                                : theme.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: memberInfo.membership.role == 'admin'
                                  ? theme.primary[300]!
                                  : theme.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                memberInfo.membership.role == 'admin'
                                    ? LucideIcons.crown
                                    : LucideIcons.user,
                                size: 10,
                                color: memberInfo.membership.role == 'admin'
                                    ? theme.primary[600]
                                    : theme.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                memberInfo.membership.role == 'admin'
                                    ? l10n.translate('group-admin')
                                    : l10n.translate('group-member'),
                                style: TextStyles.small.copyWith(
                                  color: memberInfo.membership.role == 'admin'
                                      ? theme.primary[700]
                                      : theme.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    verticalSpace(Spacing.points4),

                    // Join date and points
                    Text(
                      '${l10n.translate('joined')}: ${getDisplayDateTime(memberInfo.membership.joinedAt, locale.languageCode)}',
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),

                    if (memberInfo.membership.pointsTotal > 0) ...[
                      verticalSpace(Spacing.points4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            size: 12,
                            color: theme.primary[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${memberInfo.membership.pointsTotal} ${l10n.translate('points')}',
                            style: TextStyles.small.copyWith(
                              color: theme.primary[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Three dots menu (only show if not current user)
              if (!isCurrentUser)
                GestureDetector(
                  onTap: () => _showMemberActions(context, memberInfo, l10n),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.moreHorizontal,
                      size: 20,
                      color: theme.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(dynamic theme) {
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
          horizontalSpace(Spacing.points16),
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

  Widget _buildErrorState(dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.error[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.userX,
              color: theme.error[600],
              size: 24,
            ),
          ),
          horizontalSpace(Spacing.points16),
          Expanded(
            child: Text(
              l10n.translate('error-loading-member'),
              style: TextStyles.body.copyWith(
                color: theme.error[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(dynamic theme, GroupMemberInfo memberInfo) {
    return Icon(
      memberInfo.isAnonymous ? LucideIcons.userX : LucideIcons.user,
      color: memberInfo.membership.role == 'admin'
          ? theme.primary[600]
          : theme.grey[600],
      size: 24,
    );
  }

  Color _getAvatarColor(String? gender, dynamic theme) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return theme.primary[50]!;
      case 'female':
        return theme.secondary[50]!;
      default:
        return theme.grey[50]!;
    }
  }

  String _getLocalizedDisplayName(String displayName, AppLocalizations l10n) {
    switch (displayName) {
      case 'DELETED_USER':
        return l10n.translate('community-deleted-user');
      case 'ANONYMOUS_USER':
        return l10n.translate('community-anonymous');
      default:
        return displayName;
    }
  }

  void _showMemberActions(
      BuildContext context, GroupMemberInfo memberInfo, AppLocalizations l10n) {
    final actions = <ActionItem>[];

    // Report action - always available
    actions.add(ActionItem(
      icon: LucideIcons.flag,
      title: l10n.translate('report-user'),
      subtitle: l10n.translate('report-inappropriate-behavior'),
      onTap: () => _reportUser(context, memberInfo, l10n),
    ));

    // Admin-only actions
    if (isCurrentUserAdmin) {
      // Promote/Demote action
      if (memberInfo.membership.role == 'admin') {
        actions.add(ActionItem(
          icon: LucideIcons.userMinus,
          title: l10n.translate('demote-to-member'),
          subtitle: l10n.translate('remove-admin-privileges'),
          onTap: () => _demoteToMember(context, memberInfo, l10n),
        ));
      } else {
        actions.add(ActionItem(
          icon: LucideIcons.userPlus,
          title: l10n.translate('promote-to-admin'),
          subtitle: l10n.translate('grant-admin-privileges'),
          onTap: () => _promoteToAdmin(context, memberInfo, l10n),
        ));
      }

      // Remove from group action
      actions.add(ActionItem(
        icon: LucideIcons.userX,
        title: l10n.translate('remove-from-group'),
        subtitle: l10n.translate('permanently-remove-member'),
        isDestructive: true,
        onTap: () => _removeMember(context, memberInfo, l10n),
      ));
    }

    ActionModal.show(context, actions: actions);
  }

  void _reportUser(
      BuildContext context, GroupMemberInfo memberInfo, AppLocalizations l10n) {
    // TODO: Implement report user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('coming-soon'))),
    );
  }

  void _promoteToAdmin(
      BuildContext context, GroupMemberInfo memberInfo, AppLocalizations l10n) {
    // TODO: Implement promote to admin functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('coming-soon'))),
    );
  }

  void _demoteToMember(
      BuildContext context, GroupMemberInfo memberInfo, AppLocalizations l10n) {
    // TODO: Implement demote to member functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('coming-soon'))),
    );
  }

  void _removeMember(
      BuildContext context, GroupMemberInfo memberInfo, AppLocalizations l10n) {
    // TODO: Implement remove member functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('coming-soon'))),
    );
  }
}
