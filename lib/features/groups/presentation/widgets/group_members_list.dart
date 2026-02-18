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
import 'package:reboot_app_3/features/groups/presentation/widgets/bulk_member_actions_modal.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/providers/group_members_provider.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';

class GroupMembersList extends ConsumerStatefulWidget {
  const GroupMembersList({super.key});

  @override
  ConsumerState<GroupMembersList> createState() => _GroupMembersListState();
}

class _GroupMembersListState extends ConsumerState<GroupMembersList> {
  bool _isSelectionMode = false;
  final Set<String> _selectedCpIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedCpIds.clear();
      }
    });
  }

  void _toggleMemberSelection(String cpId) {
    setState(() {
      if (_selectedCpIds.contains(cpId)) {
        _selectedCpIds.remove(cpId);
      } else {
        _selectedCpIds.add(cpId);
      }
    });
  }

  void _selectAll(List members) {
    setState(() {
      _selectedCpIds.clear();
      for (final member in members) {
        _selectedCpIds.add(member.cpId);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedCpIds.clear();
    });
  }

  void _showBulkActionsModal(BuildContext context, String groupId, String currentUserCpId, String groupCreatorCpId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkMemberActionsModal(
        groupId: groupId,
        selectedCpIds: _selectedCpIds.toList(),
        currentUserCpId: currentUserCpId,
        groupCreatorCpId: groupCreatorCpId,
        onComplete: () {
          setState(() {
            _isSelectionMode = false;
            _selectedCpIds.clear();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      currentMembership.group.id,
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

  Future<void> _refreshMembers(String groupId) async {
    // Invalidate the members provider to trigger a refresh
    ref.invalidate(groupMembersProvider(groupId));
    // Wait a bit for the provider to reload
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget _buildMembersList(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
    List members,
    bool isCurrentUserAdmin,
    String currentUserCpId,
    String groupCreatorCpId,
    String groupId,
  ) {
    if (members.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refreshMembers(groupId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: WidgetsContainer(
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
          ),
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

    return RefreshIndicator(
      onRefresh: () => _refreshMembers(groupId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with selection controls
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
              const Spacer(),
              // Selection mode toggle (admin only)
              if (isCurrentUserAdmin) ...[
                if (!_isSelectionMode)
                  InkWell(
                    onTap: _toggleSelectionMode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primary[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primary[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkSquare,
                            size: 14,
                            color: theme.primary[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.translate('select-members'),
                            style: TextStyles.small.copyWith(
                              color: theme.primary[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _toggleSelectionMode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        l10n.translate('cancel'),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),

        // Selection controls when in selection mode
        if (_isSelectionMode) ...[
          verticalSpace(Spacing.points8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  l10n.translate('selected-count').replaceAll('{count}', '${_selectedCpIds.length}'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                horizontalSpace(Spacing.points8),
                InkWell(
                  onTap: () => _selectAll(members),
                  child: Text(
                    l10n.translate('select-all'),
                    style: TextStyles.small.copyWith(
                      color: theme.primary[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Text('|', style: TextStyles.small.copyWith(color: theme.grey[400])),
                horizontalSpace(Spacing.points8),
                InkWell(
                  onTap: _deselectAll,
                  child: Text(
                    l10n.translate('deselect-all'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        verticalSpace(Spacing.points8),

        // Members list in container
        WidgetsContainer(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                InkWell(
                  onTap: _isSelectionMode ? () => _toggleMemberSelection(members[i].cpId) : null,
                  child: Row(
                    children: [
                      // Checkbox in selection mode
                      if (_isSelectionMode) ...[
                        Checkbox(
                          value: _selectedCpIds.contains(members[i].cpId),
                          onChanged: (_) => _toggleMemberSelection(members[i].cpId),
                          activeColor: theme.primary[500],
                        ),
                        horizontalSpace(Spacing.points8),
                      ],
                      Expanded(
                        child: GroupMemberItem(
                          membershipEntity: members[i],
                          isCurrentUserAdmin: isCurrentUserAdmin,
                          currentUserCpId: currentUserCpId,
                          groupCreatorCpId: groupCreatorCpId,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < members.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.grey[200],
                    indent: _isSelectionMode ? 80 : 80,
                  ),
              ],
            ],
          ),
        ),

        // Bulk action buttons when members are selected
        if (_isSelectionMode && _selectedCpIds.isNotEmpty) ...[
          verticalSpace(Spacing.points16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBulkActionsModal(context, groupId, currentUserCpId, groupCreatorCpId),
                    icon: Icon(LucideIcons.zap, size: 16),
                    label: Text(l10n.translate('bulk-actions')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
        ),
      ),
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
