import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/public_group_card.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/join_group_modal.dart';
import 'package:reboot_app_3/features/groups/providers/filtered_public_groups_provider.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';

enum GroupFilter { all, needsCode, openJoin }

enum GroupSort { newest, oldest, mostMembers, leastMembers, mostActive }

class GroupsExplorationScreen extends ConsumerStatefulWidget {
  const GroupsExplorationScreen({super.key});

  @override
  ConsumerState<GroupsExplorationScreen> createState() =>
      _GroupsExplorationScreenState();
}

class _GroupsExplorationScreenState
    extends ConsumerState<GroupsExplorationScreen> {
  final TextEditingController _searchController = TextEditingController();
  GroupFilter _selectedFilter = GroupFilter.all;
  GroupSort _selectedSort = GroupSort.newest;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    // TODO: Check group membership properly
    const groupMembership = null;

    // Don't show exploration if user is already in a group
    if (groupMembership != null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: appBar(context, ref, 'explore-groups', false, true),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(Spacing.points24.value),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.users,
                  size: 64,
                  color: theme.primary[400],
                ),
                verticalSpace(Spacing.points16),
                Text(
                  l10n.translate('already-in-group'),
                  style: TextStyles.h5.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                verticalSpace(Spacing.points8),
                Text(
                  l10n.translate('leave-current-group-to-explore'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'explore-groups', false, true),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(Spacing.points16.value),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                CustomTextField(
                  controller: _searchController,
                  hint: l10n.translate('search-groups-placeholder'),
                  prefixIcon: LucideIcons.search,
                  inputType: TextInputType.text,
                  validator: (value) => null, // No validation needed for search
                ),

                verticalSpace(Spacing.points12),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        theme,
                        l10n,
                        GroupFilter.all,
                        l10n.translate('all-groups'),
                        LucideIcons.users,
                      ),
                      horizontalSpace(Spacing.points8),
                      _buildFilterChip(
                        theme,
                        l10n,
                        GroupFilter.openJoin,
                        l10n.translate('open-join'),
                        LucideIcons.unlock,
                      ),
                      horizontalSpace(Spacing.points8),
                      _buildFilterChip(
                        theme,
                        l10n,
                        GroupFilter.needsCode,
                        l10n.translate('code-required'),
                        LucideIcons.key,
                      ),
                    ],
                  ),
                ),

                verticalSpace(Spacing.points12),

                // Sort and Results Count
                Row(
                  children: [
                    // Sort Button
                    GestureDetector(
                      onTap: () => _showSortModal(context, theme, l10n),
                      child: WidgetsContainer(
                        padding: EdgeInsets.symmetric(
                          horizontal: Spacing.points12.value,
                          vertical: Spacing.points8.value,
                        ),
                        backgroundColor: theme.grey[50],
                        borderSide: BorderSide(
                          color: theme.grey[200]!,
                          width: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.arrowUpDown,
                              size: 16,
                              color: theme.grey[600],
                            ),
                            horizontalSpace(Spacing.points8),
                            Text(
                              _getSortLabel(l10n),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Results Count
                    Consumer(
                      builder: (context, ref, child) {
                        final groupsAsync =
                            ref.watch(filteredPublicGroupsProvider);
                        return groupsAsync.when(
                          data: (groups) => Text(
                            l10n.translate('groups-found').replaceAll(
                                  '{count}',
                                  _getFilteredGroups(groups).length.toString(),
                                ),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),
                          loading: () => Text(
                            l10n.translate('groups-found').replaceAll(
                                  '{count}',
                                  '...',
                                ),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),
                          error: (_, __) => Text(
                            l10n.translate('groups-found').replaceAll(
                                  '{count}',
                                  '0',
                                ),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Groups List
          Expanded(
            child: _isLoading
                ? const Center(child: Spinner())
                : Consumer(
                    builder: (context, ref, child) {
                      final groupsAsync =
                          ref.watch(filteredPublicGroupsProvider);
                      return groupsAsync.when(
                        data: (groups) => _buildGroupsList(theme, l10n, groups),
                        loading: () => const Center(child: Spinner()),
                        error: (error, stackTrace) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.alertCircle,
                                size: 64,
                                color: theme.error[400],
                              ),
                              verticalSpace(Spacing.points16),
                              Text(
                                l10n.translate('error-loading-groups'),
                                style: TextStyles.h6.copyWith(
                                  color: theme.error[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              verticalSpace(Spacing.points8),
                              Text(
                                error.toString(),
                                style: TextStyles.body.copyWith(
                                  color: theme.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    CustomThemeData theme,
    AppLocalizations l10n,
    GroupFilter filter,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        _performSearch();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.points12.value,
          vertical: Spacing.points8.value,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary[100] : theme.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primary[300]! : theme.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? theme.primary[700] : theme.grey[600],
            ),
            horizontalSpace(Spacing.points4),
            Text(
              label,
              style: TextStyles.caption.copyWith(
                color: isSelected ? theme.primary[700] : theme.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(CustomThemeData theme, AppLocalizations l10n,
      List<GroupEntity> allGroups) {
    final filteredGroups = _getFilteredGroups(allGroups);

    if (filteredGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.points24.value),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.searchX,
                size: 64,
                color: theme.grey[400],
              ),
              verticalSpace(Spacing.points16),
              Text(
                l10n.translate('no-groups-found'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              verticalSpace(Spacing.points8),
              Text(
                l10n.translate('try-different-filters'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(Spacing.points16.value),
      itemCount: filteredGroups.length,
      separatorBuilder: (context, index) => verticalSpace(Spacing.points16),
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return PublicGroupCard(
          group: group,
          onTap: () => _showGroupDetails(context, group),
          onJoin: () => _joinGroup(context, group),
        );
      },
    );
  }

  void _showSortModal(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(Spacing.points20.value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('sort-groups'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            verticalSpace(Spacing.points20),
            ...GroupSort.values.map((sort) {
              return ListTile(
                title: Text(_getSortLabelForSort(l10n, sort)),
                leading: Radio<GroupSort>(
                  value: sort,
                  groupValue: _selectedSort,
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                    Navigator.pop(context);
                    _performSearch();
                  },
                ),
              );
            }),
            verticalSpace(Spacing.points16),
          ],
        ),
      ),
    );
  }

  void _showGroupDetails(BuildContext context, DiscoverableGroup group) {
    // TODO: Navigate to group detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${group.name}')),
    );
  }

  void _joinGroup(BuildContext context, DiscoverableGroup group) {
    if (group.joinMethod == 'code_only') {
      // Show join with code modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const JoinGroupModal(),
      );
    } else {
      // Direct join for 'any' method
      _performDirectJoin(group);
    }
  }

  void _performDirectJoin(DiscoverableGroup group) {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual join logic
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // TODO: Implement actual join logic with backend
        // For now, just show success message

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .translate('joined-group-successfully')
                  .replaceAll('{groupName}', group.name),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _performSearch() {
    setState(() {
      _isLoading = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  List<DiscoverableGroup> _getFilteredGroups(List<GroupEntity> allGroups) {
    // Convert GroupEntity to DiscoverableGroup
    var groups =
        allGroups.map((group) => _mapGroupEntityToDiscoverable(group)).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      groups = groups.where((group) {
        return group.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (group.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            group.tags.any((tag) =>
                tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply category filter (no gender filters anymore)
    switch (_selectedFilter) {
      case GroupFilter.needsCode:
        groups = groups.where((g) => g.joinMethod == 'code_only').toList();
        break;
      case GroupFilter.openJoin:
        groups = groups.where((g) => g.joinMethod == 'any').toList();
        break;
      case GroupFilter.all:
        break;
    }

    // Apply sorting
    switch (_selectedSort) {
      case GroupSort.newest:
        groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GroupSort.oldest:
        groups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case GroupSort.mostMembers:
        groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        break;
      case GroupSort.leastMembers:
        groups.sort((a, b) => a.memberCount.compareTo(b.memberCount));
        break;
      case GroupSort.mostActive:
        // Sort by creation time since we don't have lastActivityTime in GroupEntity
        groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return groups;
  }

  String _getSortLabel(AppLocalizations l10n) {
    return _getSortLabelForSort(l10n, _selectedSort);
  }

  String _getSortLabelForSort(AppLocalizations l10n, GroupSort sort) {
    switch (sort) {
      case GroupSort.newest:
        return l10n.translate('newest-first');
      case GroupSort.oldest:
        return l10n.translate('oldest-first');
      case GroupSort.mostMembers:
        return l10n.translate('most-members');
      case GroupSort.leastMembers:
        return l10n.translate('least-members');
      case GroupSort.mostActive:
        return l10n.translate('most-active');
    }
  }

  /// Maps a GroupEntity to DiscoverableGroup for UI compatibility
  DiscoverableGroup _mapGroupEntityToDiscoverable(GroupEntity group) {
    return DiscoverableGroup(
      id: group.id,
      name: group.name,
      description: group.description,
      memberCount: 0, // TODO: Get actual member count from backend
      capacity: group.memberCapacity,
      gender: group.gender,
      joinMethod: group.joinMethod,
      createdAt: group.createdAt,
      lastActivityTime: _formatLastActivity(group.updatedAt),
      tags: _generateTagsFromGroup(group),
      challengesCount: 0, // TODO: Get actual challenges count from backend
    );
  }

  /// Formats the last activity time for display
  String _formatLastActivity(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Generates tags based on group properties
  List<String> _generateTagsFromGroup(GroupEntity group) {
    final tags = <String>[];

    // Add gender tag
    if (group.gender == 'male') {
      tags.add('Male');
    } else if (group.gender == 'female') {
      tags.add('Female');
    } else {
      tags.add('Mixed');
    }

    // Add join method tag
    if (group.joinMethod == 'code_only') {
      tags.add('Code Required');
    } else if (group.joinMethod == 'any') {
      tags.add('Open Join');
    }

    // Add generic tags
    tags.add('Support');
    tags.add('Community');

    return tags;
  }
}
