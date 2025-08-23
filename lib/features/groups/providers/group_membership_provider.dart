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
  // Get current community profile
  final profileAsync = ref.watch(currentCommunityProfileProvider);
  
  return await profileAsync.when(
    data: (profile) async {
      if (profile == null) return null;
      
      // Get membership from backend
      final service = ref.read(groupsServiceProvider);
      final membership = await service.getCurrentMembership(profile.id);
      
      if (membership == null) return null;
      
      // Get group details
      final group = await ref.read(groupsServiceProvider).getPublicGroups().first
          .where((groups) => groups.any((g) => g.id == membership.groupId))
          .map((groups) => groups.firstWhere((g) => g.id == membership.groupId))
          .first;
      
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
      
      return GroupMembership(
        group: legacyGroup,
        joinedAt: membership.joinedAt,
        memberRole: membership.role,
        totalPoints: membership.pointsTotal,
      );
    },
    loading: () async => null,
    error: (_, __) async => null,
  );
}
