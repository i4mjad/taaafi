import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/shared/models/group.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';

part 'group_membership_provider.g.dart';

/// Represents a user's current group membership status
class GroupMembership {
  final Group group;
  final DateTime joinedAt;
  final String memberRole; // 'member' or 'admin'
  final int totalPoints;

  const GroupMembership({
    required this.group,
    required this.joinedAt,
    this.memberRole = 'member',
    this.totalPoints = 0,
  });

  GroupMembership copyWith({
    Group? group,
    DateTime? joinedAt,
    String? memberRole,
    int? totalPoints,
  }) {
    return GroupMembership(
      group: group ?? this.group,
      joinedAt: joinedAt ?? this.joinedAt,
      memberRole: memberRole ?? this.memberRole,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

/// Provider for current user's group membership using real backend
@riverpod
Future<GroupMembership?> groupMembershipNotifier(ref) async {
  try {
    // Use .future to get the actual future value, bypassing AsyncValue entirely
    final profile = await ref.watch(currentCommunityProfileProvider.future);

    if (profile == null) {
      print('groupMembershipNotifier: No community profile found');
      return null;
    }

    print('groupMembershipNotifier: Got profile for user ${profile.id}');

    // Get membership from backend
    final service = ref.read(groupsServiceProvider);
    final membership = await service.getCurrentMembership(profile.id);

    if (membership == null) {
      print(
          'groupMembershipNotifier: No active membership found for user ${profile.id}');
      return null;
    }

    print(
        'groupMembershipNotifier: Found membership for group ${membership.groupId}');

    // Get specific group details by ID (not the entire public groups list)
    final repository = ref.read(groupsRepositoryProvider);
    final group = await repository.getGroupById(membership.groupId);

    if (group == null) {
      throw Exception('Group not found: ${membership.groupId}');
    }

    // Convert to legacy Group model for compatibility
    final legacyGroup = Group(
      id: group.id,
      name: group.name,
      description: group.description,
      memberCount: 0, // Will need to be fetched separately
      capacity: group.memberCapacity,
      gender: group.gender,
      createdAt: group.createdAt,
      updatedAt: group.updatedAt,
    );

    print(
        'groupMembershipNotifier: Successfully loaded membership for group ${group.name}');
    return GroupMembership(
      group: legacyGroup,
      joinedAt: membership.joinedAt,
      memberRole: membership.role,
      totalPoints: membership.pointsTotal,
    );
  } catch (error, stackTrace) {
    print('Error in groupMembershipNotifier: $error');
    print('StackTrace: $stackTrace');
    return null;
  }
}
