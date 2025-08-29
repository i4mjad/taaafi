import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_member_item.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/providers/group_members_provider.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';

class GroupMembersList extends ConsumerWidget {
  const GroupMembersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    // Get current user's group membership to determine group and role
    final currentMembershipAsync = ref.watch(groupMembershipNotifierProvider);

    return currentMembershipAsync.when(
      loading: () => _buildLoadingState(theme, l10n),
      error: (error, _) => _buildErrorState(theme, l10n),
      data: (currentMembership) {
        if (currentMembership == null) {
          return _buildNoGroupState(theme, l10n);
        }

        // Get current user's profile to get their cpId
        final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

        return currentProfileAsync.when(
          loading: () => _buildLoadingState(theme, l10n),
          error: (error, _) => _buildErrorState(theme, l10n),
          data: (currentProfile) {
            if (currentProfile == null) {
              return _buildErrorState(theme, l10n);
            }

            // Get all group members
            final groupMembersAsync =
                ref.watch(groupMembersProvider(currentMembership.group.id));

            // Get group entity to access creator information
            final groupRepository = ref.read(groupsRepositoryProvider);

            return FutureBuilder(
              future: groupRepository.getGroupById(currentMembership.group.id),
              builder: (context, groupSnapshot) {
                if (groupSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(theme, l10n);
                }

                if (groupSnapshot.hasError || !groupSnapshot.hasData) {
                  return _buildErrorState(theme, l10n);
                }

                final groupEntity = groupSnapshot.data!;

                return groupMembersAsync.when(
                  loading: () => _buildLoadingState(theme, l10n),
                  error: (error, _) => _buildErrorState(theme, l10n),
                  data: (members) {
                    return _buildMembersList(
                      context,
                      theme,
                      l10n,
                      members,
                      currentMembership.memberRole == 'admin',
                      currentProfile.id,
                      groupEntity.createdByCpId,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    List members,
    bool isCurrentUserAdmin,
    String currentUserCpId,
    String groupCreatorCpId,
  ) {
    if (members.isEmpty) {
      return WidgetsContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              LucideIcons.users,
              size: 48,
              color: theme.grey[400],
            ),
            verticalSpace(Spacing.points16),
            Text(
              l10n.translate('no-members-found'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Sort members: admins first, then by join date
    members.sort((a, b) {
      // Admins first
      if (a.role == 'admin' && b.role != 'admin') return -1;
      if (b.role == 'admin' && a.role != 'admin') return 1;

      // Then by join date (earliest first)
      return a.joinedAt.compareTo(b.joinedAt);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                l10n.translate('group-members'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              horizontalSpace(Spacing.points8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${members.length}',
                  style: TextStyles.small.copyWith(
                    color: theme.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        verticalSpace(Spacing.points8),

        // Members list in container
        WidgetsContainer(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                GroupMemberItem(
                  membershipEntity: members[i],
                  isCurrentUserAdmin: isCurrentUserAdmin,
                  currentUserCpId: currentUserCpId,
                  groupCreatorCpId: groupCreatorCpId,
                ),
                if (i < members.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.grey[200],
                    indent: 80,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spinner(),
          verticalSpace(Spacing.points16),
          Text(
            l10n.translate('loading-group-members'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: theme.error[500],
          ),
          verticalSpace(Spacing.points16),
          Text(
            l10n.translate('error-loading-members'),
            style: TextStyles.h6.copyWith(
              color: theme.error[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoGroupState(dynamic theme, AppLocalizations l10n) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            LucideIcons.userX,
            size: 48,
            color: theme.grey[400],
          ),
          verticalSpace(Spacing.points16),
          Text(
            l10n.translate('not-in-group'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
