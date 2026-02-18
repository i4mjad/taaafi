import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';

part 'filtered_public_groups_provider.g.dart';

/// Provider that fetches public groups filtered by current user's gender
@riverpod
Stream<List<GroupEntity>> filteredPublicGroups(
    FilteredPublicGroupsRef ref) async* {
  // Get user profile to determine gender
  final userProfile = await ref.watch(userProfileNotifierProvider.future);

  if (userProfile == null) {
    yield [];
    return;
  }

  // Get public groups stream
  final groupsService = ref.watch(groupsServiceProvider);

  // Listen to public groups and filter by user gender and group status
  await for (final allGroups in groupsService.getPublicGroups()) {
    // Filter groups by user's gender and group status
    final filteredGroups = allGroups.where((group) {
      // Only show active groups (exclude deleted/inactive groups)
      if (!group.isActive) {
        return false;
      }

      // Don't show paused groups
      if (group.isPaused) {
        return false;
      }

      // Convert user gender to lowercase for comparison
      final userGender = userProfile.gender.toLowerCase();
      final groupGender = group.gender.toLowerCase();

      // Show groups that:
      // 1. Match the user's gender exactly
      // 2. Are marked as 'mixed' (if that's a valid option in your system)
      return groupGender == userGender || groupGender == 'mixed';
    }).toList();

    yield filteredGroups;
  }
}
