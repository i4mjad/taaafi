import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/action_modal.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/groups/application/group_member_management_controller.dart';

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
  final String groupCreatorCpId;

  const GroupMemberItem({
    super.key,
    required this.membershipEntity,
    required this.isCurrentUserAdmin,
    required this.currentUserCpId,
    required this.groupCreatorCpId,
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
              // Avatar - always show, but different for anonymous users
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
                child: memberInfo.isAnonymous
                    ? _buildAnonymousAvatar(theme, memberInfo)
                    : (memberInfo.avatarUrl != null
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
                        : _buildDefaultAvatar(theme, memberInfo)),
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
                        // Activity indicator (green dot if active in 24h)
                        if (memberInfo.membership.lastActiveAt != null &&
                            DateTime.now()
                                    .difference(
                                        memberInfo.membership.lastActiveAt!)
                                    .inHours <
                                24)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: theme.success[500],
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLocalizedDisplayName(
                                    memberInfo.displayName, l10n),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.grey[900],
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              verticalSpace(Spacing.points4),
                              // Role badge
                              Row(
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
                                    style: TextStyles.bodyTiny.copyWith(
                                      color:
                                          memberInfo.membership.role == 'admin'
                                              ? theme.primary[700]
                                              : theme.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    verticalSpace(Spacing.points4),

                    // Activity info: Last active & message count
                    Row(
                      children: [
                        // Last active
                        if (memberInfo.membership.lastActiveAt != null) ...[
                          Icon(
                            LucideIcons.clock,
                            size: 11,
                            color: theme.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLastActiveText(
                                memberInfo.membership.lastActiveAt!, l10n),
                            style: TextStyles.bottomNavigationBarLabel.copyWith(
                              color: theme.grey[600],
                            ),
                          ),
                        ] else
                          Text(
                            l10n.translate('never-active'),
                            style: TextStyles.bottomNavigationBarLabel.copyWith(
                              color: theme.grey[500],
                            ),
                          ),

                        const SizedBox(width: 8),

                        // Message count
                        if (memberInfo.membership.messageCount > 0) ...[
                          Icon(
                            LucideIcons.messageCircle,
                            size: 11,
                            color: theme.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${memberInfo.membership.messageCount}',
                            style: TextStyles.bottomNavigationBarLabel.copyWith(
                              color: theme.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(width: 8),

                        // Engagement badge
                        _buildEngagementBadge(
                            memberInfo.membership.engagementLevel, theme, l10n),
                      ],
                    ),

                    verticalSpace(Spacing.points4),

                    // Join date
                    Text(
                      '${l10n.translate('joined')}: ${getDisplayDateTime(memberInfo.membership.joinedAt, locale.languageCode)}',
                      style: TextStyles.bottomNavigationBarLabel.copyWith(
                        color: theme.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Three dots menu (only show if not current user)
              if (!isCurrentUser)
                GestureDetector(
                  onTap: () =>
                      _showMemberActions(context, memberInfo, l10n, ref),
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
      LucideIcons.user,
      color: memberInfo.membership.role == 'admin'
          ? theme.primary[600]
          : theme.grey[600],
      size: 24,
    );
  }

  Widget _buildAnonymousAvatar(dynamic theme, GroupMemberInfo memberInfo) {
    return Icon(
      LucideIcons.user,
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

  /// Get last active text (Sprint 2 - Feature 2.1)
  String _getLastActiveText(DateTime lastActiveAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt);

    if (difference.inMinutes < 5) {
      return l10n.translate('active-now');
    } else if (difference.inHours < 1) {
      return l10n.translate('active-minutes-ago')
          .replaceAll('{minutes}', '${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return l10n.translate('active-hours-ago')
          .replaceAll('{hours}', '${difference.inHours}');
    } else if (difference.inDays < 7) {
      return l10n.translate('active-days-ago')
          .replaceAll('{days}', '${difference.inDays}');
    } else {
      final weeks = (difference.inDays / 7).floor();
      return l10n.translate('active-weeks-ago')
          .replaceAll('{weeks}', '$weeks');
    }
  }

  /// Build engagement badge (Sprint 2 - Feature 2.1)
  Widget _buildEngagementBadge(
      String level, dynamic theme, AppLocalizations l10n) {
    Color badgeColor;
    String labelKey;

    switch (level) {
      case 'high':
        badgeColor = theme.success[500]!;
        labelKey = 'high-engagement';
        break;
      case 'medium':
        badgeColor = theme.warning[500]!;
        labelKey = 'medium-engagement';
        break;
      case 'low':
      default:
        badgeColor = theme.grey[400]!;
        labelKey = 'low-engagement';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.translate(labelKey),
            style: TextStyles.tinyBold.copyWith(
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberActions(BuildContext context, GroupMemberInfo memberInfo,
      AppLocalizations l10n, WidgetRef ref) {
    final actions = <ActionItem>[];

    // Report action - always available
    actions.add(ActionItem(
      icon: LucideIcons.flag,
      title: l10n.translate('report-user'),
      subtitle: l10n.translate('report-inappropriate-behavior'),
      onTap: () => _reportUser(context, memberInfo, l10n, ref),
    ));

    // Admin-only actions
    if (isCurrentUserAdmin) {
      final isGroupCreator = memberInfo.membership.cpId == groupCreatorCpId;

      // Promote/Demote action (not allowed for group creator)
      if (memberInfo.membership.role == 'admin') {
        actions.add(ActionItem(
          icon: LucideIcons.userMinus,
          title: l10n.translate('demote-to-member'),
          subtitle: l10n.translate('remove-admin-privileges'),
          onTap: () =>
              _demoteToMember(context, memberInfo, l10n, isGroupCreator, ref),
        ));
      } else {
        actions.add(ActionItem(
          icon: LucideIcons.userPlus,
          title: l10n.translate('promote-to-admin'),
          subtitle: l10n.translate('grant-admin-privileges'),
          onTap: () => _promoteToAdmin(context, memberInfo, l10n, ref),
        ));
      }

      // Remove from group action (not allowed for group creator)
      actions.add(ActionItem(
        icon: LucideIcons.userX,
        title: l10n.translate('remove-from-group'),
        subtitle: l10n.translate('permanently-remove-member'),
        isDestructive: true,
        onTap: () =>
            _removeMember(context, memberInfo, l10n, isGroupCreator, ref),
      ));
    }

    ActionModal.show(context, actions: actions);
  }

  void _reportUser(BuildContext context, GroupMemberInfo memberInfo,
      AppLocalizations l10n, WidgetRef ref) {
    final actions = <ActionItem>[
      ActionItem(
        icon: LucideIcons.alertTriangle,
        title: l10n.translate('report-inappropriate-content'),
        onTap: () => _submitUserReport(
            context, memberInfo, 'inappropriate-content', l10n, ref),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.userMinus,
        title: l10n.translate('report-harassment'),
        onTap: () =>
            _submitUserReport(context, memberInfo, 'harassment', l10n, ref),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.shield,
        title: l10n.translate('report-spam'),
        onTap: () => _submitUserReport(context, memberInfo, 'spam', l10n, ref),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.frown,
        title: l10n.translate('report-hate-speech'),
        onTap: () =>
            _submitUserReport(context, memberInfo, 'hate-speech', l10n, ref),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.moreHorizontal,
        title: l10n.translate('report-other-reason'),
        onTap: () => _submitUserReport(context, memberInfo, 'other', l10n, ref),
        isDestructive: true,
      ),
    ];

    ActionModal.show(context,
        actions: actions, title: l10n.translate('report-reason'));
  }

  /// Submit a user report
  void _submitUserReport(BuildContext context, GroupMemberInfo memberInfo,
      String reportTypeId, AppLocalizations l10n, WidgetRef ref) async {
    // Get the context and ref for the async operation
    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Close the action modal first
      navigator.pop();

      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.reportUser(
        reportedUserCpId: memberInfo.membership.cpId,
        reportMessage: l10n.translate('inappropriate-behavior-in-group'),
      );

      if (result.success) {
        getSuccessSnackBar(context, 'report-submitted-successfully');
      } else {
        getErrorSnackBar(
            context, result.errorKey ?? 'report-submission-failed');
      }
    } catch (e) {
      getErrorSnackBar(context, 'report-submission-failed');
    }
  }

  void _promoteToAdmin(BuildContext context, GroupMemberInfo memberInfo,
      AppLocalizations l10n, WidgetRef ref) async {
    if (!context.mounted) return;

    try {
      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.promoteMemberToAdmin(
        groupId: memberInfo.membership.groupId,
        memberCpId: memberInfo.membership.cpId,
      );

      if (result.success) {
        getSuccessSnackBar(context, 'member-promoted-successfully');
      } else {
        getErrorSnackBar(
            context, result.errorKey ?? 'failed-to-promote-member');
      }
    } catch (e) {
      getErrorSnackBar(context, 'failed-to-promote-member');
    }
  }

  void _demoteToMember(BuildContext context, GroupMemberInfo memberInfo,
      AppLocalizations l10n, bool isGroupCreator, WidgetRef ref) async {
    if (isGroupCreator) {
      getErrorSnackBar(context, 'cannot-demote-group-creator');
      return;
    }

    if (!context.mounted) return;

    try {
      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.demoteMemberToMember(
        groupId: memberInfo.membership.groupId,
        memberCpId: memberInfo.membership.cpId,
      );

      if (result.success) {
        getSuccessSnackBar(context, 'member-demoted-successfully');
      } else {
        getErrorSnackBar(context, result.errorKey ?? 'failed-to-demote-member');
      }
    } catch (e) {
      getErrorSnackBar(context, 'failed-to-demote-member');
    }
  }

  void _removeMember(BuildContext context, GroupMemberInfo memberInfo,
      AppLocalizations l10n, bool isGroupCreator, WidgetRef ref) async {
    if (isGroupCreator) {
      getErrorSnackBar(context, 'cannot-remove-group-creator');
      return;
    }

    if (!context.mounted) return;

    try {
      final controller =
          ref.read(groupMemberManagementControllerProvider.notifier);
      final result = await controller.removeMemberFromGroup(
        groupId: memberInfo.membership.groupId,
        memberCpId: memberInfo.membership.cpId,
      );

      if (result.success) {
        getSuccessSnackBar(context, 'member-removed-successfully');
      } else {
        getErrorSnackBar(context, result.errorKey ?? 'failed-to-remove-member');
      }
    } catch (e) {
      getErrorSnackBar(context, 'failed-to-remove-member');
    }
  }
}
