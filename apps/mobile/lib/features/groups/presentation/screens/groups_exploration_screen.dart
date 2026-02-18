import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/public_group_card.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/simple_join_code_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/group_details_modal.dart';

import 'package:reboot_app_3/features/groups/providers/filtered_public_groups_provider.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/join_result_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';

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
                          error: (error, stackTrace) {
                            print(error);
                            return Text(
                              l10n.translate('groups-found').replaceAll(
                                    '{count}',
                                    '0',
                                  ),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                              ),
                            );
                          },
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
    // Convert DiscoverableGroup to GroupEntity for the modal
    final groupEntity = GroupEntity(
      id: group.id,
      name: group.name,
      description: group.description ?? '',
      gender: group.gender,
      preferredLanguage: _validateLanguage(group.preferredLanguage),
      memberCapacity: group.capacity,
      memberCount: group.memberCount,
      adminCpId: '', // Not needed for details display
      createdByCpId: '', // Not needed for details display
      visibility: 'public', // All discoverable groups are public
      joinMethod: group.joinMethod,
      createdAt: group.createdAt,
      updatedAt: group.createdAt,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => GroupDetailsModal(
        group: groupEntity,
        onJoin: () {
          Navigator.of(context).pop();
          _joinGroup(context, group);
        },
      ),
    );
  }

  Future<void> _joinGroup(BuildContext context, DiscoverableGroup group) async {
    final l10n = AppLocalizations.of(context);

    // Check if user can join (cooldown check)
    final profileAsync = ref.read(currentCommunityProfileProvider);
    final profile = await profileAsync.when(
      data: (profile) async => profile,
      loading: () async => null,
      error: (_, __) async => null,
    );

    if (profile == null) {
      getErrorSnackBar(context, 'profile-required');
      return;
    }

    final canJoin = await ref.read(canJoinGroupProvider(profile.id).future);
    if (!canJoin) {
      getErrorSnackBar(context, 'cooldown-active-error');
      return;
    }

    if (group.joinMethod == 'code_only') {
      // Show simple join with code modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SimpleJoinCodeModal(groupName: group.name),
      );
    } else {
      // Direct join for 'any' method
      _performDirectJoin(group);
    }
  }

  Future<void> _performDirectJoin(DiscoverableGroup group) async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current community profile
      final profileAsync = ref.read(currentCommunityProfileProvider);
      final profile = await profileAsync.when(
        data: (profile) async => profile,
        loading: () async => null,
        error: (_, __) async => null,
      );

      if (profile == null) {
        _showError(l10n.translate('profile-required'));
        return;
      }

      final result =
          await ref.read(groupsControllerProvider.notifier).joinGroupDirectly(
                groupId: group.id,
                cpId: profile.id,
              );

      if (!mounted) return;

      if (result.success) {
        getSuccessSnackBar(context, 'group-joined-successfully');
        // Navigate to group screen after successful join
        if (mounted) {
          context.goNamed(RouteNames.groups.name);
        }
      } else {
        _showError(_getJoinErrorMessage(result, l10n));
      }
    } catch (error) {
      if (mounted) {
        _showError(l10n.translate('unexpected-error'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    // Convert GroupEntity to DiscoverableGroup with real member counts
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

  /// Maps GroupEntity to DiscoverableGroup with real member count
  DiscoverableGroup _mapGroupEntityToDiscoverable(GroupEntity group) {
    return DiscoverableGroup(
      id: group.id,
      name: group.name,
      description: group.description,
      memberCount: group.memberCount, // Real member count from backend
      capacity: group.memberCapacity,
      gender: group.gender,
      preferredLanguage: group.preferredLanguage,
      joinMethod: group.joinMethod,
      createdAt: group.createdAt,
      lastActivityTime:
          _formatLastActivity(group.updatedAt, AppLocalizations.of(context)),
      tags: [], // Only show real tags when available from backend
    );
  }

  /// Formats the last activity time for display
  String _formatLastActivity(DateTime updatedAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return l10n.translate('just-created');
    } else if (difference.inHours < 1) {
      return l10n
          .translate('group-hours-ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inDays < 1) {
      return l10n
          .translate('group-days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inDays < 7) {
      return l10n
          .translate('group-days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else {
      final weeks = (difference.inDays / 7).floor();
      return l10n
          .translate('group-weeks-ago')
          .replaceAll('{weeks}', weeks.toString());
    }
  }

  void _showError(String message) {
    getErrorSnackBar(context, 'join-group-failed');
  }

  String _getJoinErrorMessage(JoinResultEntity result, AppLocalizations l10n) {
    switch (result.errorType) {
      case JoinErrorType.alreadyInGroup:
        return l10n.translate('already-in-group-error');
      case JoinErrorType.cooldownActive:
        return l10n.translate('cooldown-active-error');
      case JoinErrorType.capacityFull:
        return l10n.translate('group-full-error');
      case JoinErrorType.invalidCode:
      case JoinErrorType.expiredCode:
        return l10n.translate('invalid-join-code-error');
      case JoinErrorType.genderMismatch:
        return l10n.translate('gender-mismatch-error');
      case JoinErrorType.groupNotFound:
        return l10n.translate('group-not-found-error');
      case JoinErrorType.groupInactive:
      case JoinErrorType.groupPaused:
        return l10n.translate('group-inactive-error');
      case JoinErrorType.userBanned:
        return l10n.translate('user-banned-error');
      default:
        return result.errorMessage ?? l10n.translate('join-group-failed');
    }
  }

  /// Helper method to validate and provide fallback for group language
  String _validateLanguage(String? language) {
    if (language != null && language.isNotEmpty) {
      final validLanguages = ['arabic', 'english'];
      if (validLanguages.contains(language.toLowerCase())) {
        return language.toLowerCase();
      }
    }
    // Default to Arabic for missing or invalid values
    return 'arabic';
  }
}
