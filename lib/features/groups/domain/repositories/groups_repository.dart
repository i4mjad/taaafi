import '../entities/group_entity.dart';
import '../entities/group_membership_entity.dart';
import '../entities/join_result_entity.dart';

abstract class GroupsRepository {
  /// Get current user's active membership
  Future<GroupMembershipEntity?> getCurrentMembership(String cpId);

  /// Get group by ID
  Future<GroupEntity?> getGroupById(String groupId);

  /// Get public groups for discovery
  Stream<List<GroupEntity>> getPublicGroups();

  /// Create a new group
  Future<CreateGroupResultEntity> createGroup({
    required String name,
    required String description,
    required int memberCapacity,
    required String visibility,
    required String joinMethod,
    required String creatorCpId,
    required String preferredLanguage,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  });

  /// Join a group by ID (for public groups with 'any' join method)
  Future<JoinResultEntity> joinGroupDirectly({
    required String groupId,
    required String cpId,
  });

  /// Join a group using a code
  Future<JoinResultEntity> joinGroupWithCode({
    required String groupId,
    required String joinCode,
    required String cpId,
  });

  /// Leave current group
  Future<LeaveResultEntity> leaveGroup({
    required String cpId,
  });

  /// Check if user can join groups (cooldown, existing membership, etc.)
  Future<bool> canJoinGroup(String cpId);

  /// Get next allowed join time for user
  Future<DateTime?> getNextJoinAllowedAt(String cpId);

  /// Get current member count for a group
  Future<int> getGroupMemberCount(String groupId);

  /// Get all active members of a group
  Future<List<GroupMembershipEntity>> getGroupMembers(String groupId);

  /// Get active members of a group sorted by join date (oldest first)
  Future<List<GroupMembershipEntity>> getActiveGroupMembersSorted(
      String groupId);

  /// Promote a member to admin role
  Future<void> promoteMemberToAdmin({
    required String groupId,
    required String cpId,
  });

  /// Demote an admin to member role
  Future<void> demoteMemberToMember({
    required String groupId,
    required String cpId,
  });

  /// Remove a member from the group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String cpId,
  });

  /// Update group admin
  Future<void> updateGroupAdmin({
    required String groupId,
    required String newAdminCpId,
  });

  /// Mark a group as inactive/deleted
  Future<void> markGroupAsInactive(String groupId);

  /// Find group by join code
  Future<GroupEntity?> findGroupByJoinCode(String joinCode);

  /// Update group privacy settings (visibility and join method)
  Future<void> updateGroupPrivacySettings({
    required String groupId,
    required String adminCpId,
    String? visibility,
    String? joinMethod,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  });

  /// Update group member capacity (admin only)
  Future<void> updateGroupCapacity({
    required String groupId,
    required String adminCpId,
    required int newCapacity,
  });

  /// Update group details (admin only)
  Future<void> updateGroupDetails({
    required String groupId,
    required String adminCpId,
    String? name,
    String? description,
  });

  // ==================== ACTIVITY TRACKING (Sprint 2 - Feature 2.1) ====================
  
  /// Get members with activity data
  Future<List<GroupMembershipEntity>> getMembersWithActivity(String groupId);

  /// Get inactive members (not active for X days)
  Future<List<GroupMembershipEntity>> getInactiveMembers(
    String groupId,
    int inactiveDays,
  );

  /// Update member last active timestamp
  Future<void> updateMemberActivity({
    required String groupId,
    required String cpId,
  });
}
