import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/group_membership_entity.dart';
import '../domain/services/group_activity_service.dart';
import '../application/groups_providers.dart';

part 'group_activity_provider.g.dart';

// ==================== SERVICE PROVIDER ====================

@riverpod
GroupActivityService groupActivityService(GroupActivityServiceRef ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupActivityService(repository);
}

// ==================== DATA PROVIDERS ====================

/// Provider for fetching members with activity data for a specific group
@riverpod
Future<List<GroupMembershipEntity>> groupMembersWithActivity(
  GroupMembersWithActivityRef ref,
  String groupId,
) async {
  final service = ref.watch(groupActivityServiceProvider);
  return await service.getMembersWithActivity(groupId: groupId);
}

/// Provider for fetching inactive members (not active for X days)
@riverpod
Future<List<GroupMembershipEntity>> inactiveGroupMembers(
  InactiveGroupMembersRef ref,
  String groupId, {
  int days = 7,
}) async {
  final service = ref.watch(groupActivityServiceProvider);
  return await service.getInactiveMembers(
    groupId: groupId,
    inactiveDays: days,
  );
}

/// Provider for group activity statistics
@riverpod
Future<GroupActivityStats> groupActivityStats(
  GroupActivityStatsRef ref,
  String groupId,
) async {
  final service = ref.watch(groupActivityServiceProvider);
  return await service.getMemberActivityStats(groupId: groupId);
}

// ==================== SORTED/FILTERED DATA PROVIDERS ====================

/// Provider for members sorted by activity (most recent first)
@riverpod
Future<List<GroupMembershipEntity>> membersSortedByActivity(
  MembersSortedByActivityRef ref,
  String groupId,
) async {
  final service = ref.watch(groupActivityServiceProvider);
  final members = await service.getMembersWithActivity(groupId: groupId);
  return service.sortMembersByActivity(members);
}

/// Provider for members sorted by engagement score (highest first)
@riverpod
Future<List<GroupMembershipEntity>> membersSortedByEngagement(
  MembersSortedByEngagementRef ref,
  String groupId,
) async {
  final service = ref.watch(groupActivityServiceProvider);
  final members = await service.getMembersWithActivity(groupId: groupId);
  return service.sortMembersByEngagement(members);
}

/// Provider for filtering members by engagement level
@riverpod
Future<List<GroupMembershipEntity>> membersByEngagementLevel(
  MembersByEngagementLevelRef ref,
  String groupId,
  String level, // 'high', 'medium', 'low'
) async {
  final service = ref.watch(groupActivityServiceProvider);
  final members = await service.getMembersWithActivity(groupId: groupId);
  return service.filterMembersByEngagementLevel(members, level);
}

