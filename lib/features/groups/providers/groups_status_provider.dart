import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';

part 'groups_status_provider.g.dart';

enum GroupsStatus {
  loading,
  needsCommunityProfile,
  cooldownActive,
  canJoinGroup,
  alreadyInGroup,
  canCreateGroup,
  hasInvitations,
}

@riverpod
Future<GroupsStatus> groupsStatus(Ref ref) async {
  final hasCommunityProfileAsync = ref.watch(hasCommunityProfileProvider);
  final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
  final groupMembershipAsync = ref.watch(groupMembershipNotifierProvider);

  // Check if any provider is still loading
  if (hasCommunityProfileAsync.isLoading ||
      currentProfileAsync.isLoading ||
      groupMembershipAsync.isLoading) {
    return GroupsStatus.loading;
  }

  // Check for errors in any provider
  if (hasCommunityProfileAsync.hasError ||
      currentProfileAsync.hasError ||
      groupMembershipAsync.hasError) {
    print('Provider error detected:');
    if (hasCommunityProfileAsync.hasError) {
      print(
          '  hasCommunityProfileAsync error: ${hasCommunityProfileAsync.error}');
    }
    if (currentProfileAsync.hasError) {
      print('  currentProfileAsync error: ${currentProfileAsync.error}');
    }
    if (groupMembershipAsync.hasError) {
      print('  groupMembershipAsync error: ${groupMembershipAsync.error}');
    }
    return GroupsStatus.needsCommunityProfile;
  }

  // All providers have data, now process the values
  final hasCommunityProfile = hasCommunityProfileAsync.value;
  final currentProfile = currentProfileAsync.value;
  final groupMembership = groupMembershipAsync.value;

  print('hasCommunityProfile: $hasCommunityProfile');
  print('currentProfile: ${currentProfile?.id}');
  print('groupMembership: ${groupMembership?.group.id}');

  // If user doesn't have a community profile, they need to create one first
  if (hasCommunityProfile != true) {
    return GroupsStatus.needsCommunityProfile;
  }

  // If current profile is null, user needs to create a community profile
  if (currentProfile == null) {
    return GroupsStatus.needsCommunityProfile;
  }

  // Check if user is already in a group
  if (groupMembership != null) {
    return GroupsStatus.alreadyInGroup;
  }

  // Check if user has cooldown active
  final canJoinAsync = ref.watch(canJoinGroupProvider(currentProfile.id));
  if (canJoinAsync.hasValue && !canJoinAsync.value!) {
    return GroupsStatus.cooldownActive;
  }

  // TODO: Check if user has pending invitations
  // For now, we'll simulate having invitations for demo purposes
  final hasInvitations = false; // TODO: Replace with actual invitation check

  if (hasInvitations) {
    return GroupsStatus.hasInvitations;
  }

  return GroupsStatus.canJoinGroup;
}
