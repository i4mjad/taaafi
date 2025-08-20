import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

part 'groups_status_provider.g.dart';

enum GroupsStatus {
  loading,
  needsCommunityProfile,
  canJoinGroup,
  alreadyInGroup,
  canCreateGroup,
  hasInvitations,
}

@riverpod
GroupsStatus groupsStatus(Ref ref) {
  final hasCommunityProfileAsync = ref.watch(hasCommunityProfileProvider);
  final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

  // If community profile check is still loading, return loading status
  if (hasCommunityProfileAsync.isLoading) {
    return GroupsStatus.loading;
  }

  return hasCommunityProfileAsync.when(
    data: (hasCommunityProfile) {
      // If user doesn't have a community profile, they need to create one first
      if (!hasCommunityProfile) {
        return GroupsStatus.needsCommunityProfile;
      }

      // If user has a community profile, check if they're already in a group
      return currentProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return GroupsStatus.needsCommunityProfile;
          }

          // TODO: Check if user is already in a group
          // For now, we'll assume they can join a group
          // This should be updated when group membership data is available
          final isInGroup =
              false; // TODO: Replace with actual group membership check

          if (isInGroup) {
            return GroupsStatus.alreadyInGroup;
          }

          // TODO: Check if user has pending invitations
          // For now, we'll simulate having invitations for demo purposes
          final hasInvitations =
              false; // TODO: Replace with actual invitation check

          if (hasInvitations) {
            return GroupsStatus.hasInvitations;
          }

          return GroupsStatus.canJoinGroup;
        },
        error: (_, __) => GroupsStatus.needsCommunityProfile,
        loading: () => GroupsStatus.loading,
      );
    },
    error: (_, __) => GroupsStatus.needsCommunityProfile,
    loading: () => GroupsStatus.loading,
  );
}
