import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/member_profile_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/edit_member_profile_modal.dart';

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

        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showMemberProfile(context, profile, memberInfo, ref);
          },
          child: Container(
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
                      // Name with admin shield
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
                            child: Row(
                              children: [
                                // Admin shield icon
                                if (memberInfo.membership.role == 'admin') ...[
                                  Icon(
                                    LucideIcons.shield,
                                    size: 14,
                                    color: theme.primary[600],
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    _getLocalizedDisplayName(
                                        memberInfo.displayName, l10n),
                                    style: TextStyles.footnote.copyWith(
                                      color:
                                          memberInfo.membership.role == 'admin'
                                              ? theme.primary[700]
                                              : theme.grey[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                          // Last active - improved logic (Sprint 4 Enhancement)
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
                              style:
                                  TextStyles.bottomNavigationBarLabel.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                          ] else ...[
                            // If no lastActiveAt, check if recently joined
                            Icon(
                              LucideIcons.clock,
                              size: 11,
                              color: theme.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getActivityFallbackText(
                                  memberInfo.membership.joinedAt, l10n),
                              style:
                                  TextStyles.bottomNavigationBarLabel.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                          ],

                          const SizedBox(width: 8),

                          // Engagement badge
                          _buildEngagementBadge(
                              memberInfo.membership.engagementLevel,
                              theme,
                              l10n),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron icon (respects RTL/LTR)
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.chevronLeft
                      : LucideIcons.chevronRight,
                  size: 18,
                  color: theme.grey[400],
                ),
              ],
            ),
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

  /// Get activity fallback text when lastActiveAt is null (Sprint 4 Enhancement)
  String _getActivityFallbackText(DateTime joinedAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    // Backward compatibility: For existing users without lastActiveAt tracking
    // We assume they're active members rather than showing "No activity yet"

    if (difference.inMinutes < 60) {
      // Just joined (< 1 hour)
      return l10n.translate('active-now');
    } else if (difference.inHours < 24) {
      // Joined recently (< 24 hours)
      return l10n.translate('joined-recently');
    } else if (difference.inDays <= 7) {
      // Joined within a week
      return l10n.translate('joined-recently');
    } else {
      // Older member - assume active (backward compatibility)
      // Once they send a message, lastActiveAt will be set
      return l10n.translate('active-member');
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
        badgeColor = theme.warn[500]!;
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

  /// Show member profile modal (Sprint 4 - Feature 4.1)
  void _showMemberProfile(
    BuildContext context,
    dynamic profile,
    GroupMemberInfo memberInfo,
    WidgetRef ref,
  ) async {
    final isOwnProfile = memberInfo.membership.cpId == currentUserCpId;

    // Force fresh fetch from Firestore - no cache (Sprint 4 Enhancement)
    ref.invalidate(communityProfileByIdProvider(memberInfo.membership.cpId));
    final freshProfile = await ref.read(
      communityProfileByIdProvider(memberInfo.membership.cpId).future,
    );

    if (!context.mounted || freshProfile == null) {
      return;
    }

    final isGroupCreator = memberInfo.membership.cpId == groupCreatorCpId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => MemberProfileModal(
        profile: freshProfile,
        membership: memberInfo.membership,
        isOwnProfile: isOwnProfile,
        isCurrentUserAdmin: isCurrentUserAdmin,
        isGroupCreator: isGroupCreator,
        // Only provide onEdit for own profile (Sprint 4 Enhancement)
        onEdit: isOwnProfile
            ? () {
                Navigator.of(modalContext).pop();
                // Open edit profile modal (Sprint 4 Enhancement)
                _showEditProfileModal(context, freshProfile, ref);
              }
            : null,
        // Only provide onMessage for other members
        onMessage: !isOwnProfile
            ? () {
                // TODO: Navigate to direct message (Future sprint)
                Navigator.of(modalContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        AppLocalizations.of(context).translate('coming-soon')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            : null,
      ),
    );
  }

  /// Show edit profile modal (Sprint 4 Enhancement)
  void _showEditProfileModal(
      BuildContext context, dynamic profile, WidgetRef ref) {
    showEditProfileModal(
      context: context,
      profile: profile,
      onSave: (bio, interests) async {
        try {
          final repository = ref.read(communityRepositoryProvider);

          // Update bio
          if (bio != profile.groupBio) {
            await repository.updateGroupBio(profile.id, bio);
          }

          // Update interests
          if (interests.toString() != profile.interests.toString()) {
            await repository.updateInterests(profile.id, interests);
          }

          // Invalidate cache to force fresh fetch next time
          ref.invalidate(currentCommunityProfileProvider);
          ref.invalidate(communityProfileByIdProvider(profile.id));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)
                      .translate('group-profile-updated'),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          rethrow;
        }
      },
    );
  }
}
