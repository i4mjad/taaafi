import '../models/group_model.dart';
import '../models/group_membership_model.dart';

/// Abstract interface for groups data operations
abstract class GroupsDataSource {
  /// Get current user's active membership
  Future<GroupMembershipModel?> getCurrentMembership(String cpId);

  /// Get group by ID
  Future<GroupModel?> getGroupById(String groupId);

  /// Get public groups for discovery
  Stream<List<GroupModel>> getPublicGroups();

  /// Create a new group
  Future<String> createGroup(GroupModel group);

  /// Create group membership
  Future<String> createMembership(GroupMembershipModel membership);

  /// Update group membership
  Future<void> updateMembership(GroupMembershipModel membership);

  /// Check if user can join groups (cooldown, bans)
  Future<bool> canJoinGroup(String cpId);

  /// Get next allowed join time for user
  Future<DateTime?> getNextJoinAllowedAt(String cpId);

  /// Set cooldown for user after leaving group
  Future<void> setCooldown(String cpId, DateTime nextJoinAllowedAt);

  /// Verify join code for a group
  Future<bool> verifyJoinCode(String groupId, String joinCode);

  /// Increment join code usage count
  Future<void> incrementJoinCodeUsage(String groupId);

  /// Check user's Plus status
  Future<bool> isUserPlus(String cpId);

  /// Check user's gender
  Future<String?> getUserGender(String cpId);

  /// Get current member count for a group
  Future<int> getGroupMemberCount(String groupId);

  /// Get all active members of a group
  Future<List<GroupMembershipModel>> getGroupMembers(String groupId);

  /// Get active members of a group sorted by join date (oldest first)
  Future<List<GroupMembershipModel>> getActiveGroupMembersSorted(
      String groupId);

  /// Update group
  Future<void> updateGroup(GroupModel group);

  /// Update group capacity with transaction (atomic with member count check)
  Future<void> updateGroupCapacityTransactional({
    required String groupId,
    required int newCapacity,
  });

  /// Update group details with transaction (atomic update)
  Future<void> updateGroupDetailsTransactional({
    required String groupId,
    required String name,
    required String description,
  });

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

  /// Remove a member from the group (set membership as inactive)
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String cpId,
  });

  /// Mark a group as inactive/deleted
  Future<void> markGroupAsInactive(String groupId);

  /// Find group by join code
  Future<GroupModel?> findGroupByJoinCode(String joinCode);

  // ==================== ACTIVITY TRACKING (Sprint 2 - Feature 2.1) ====================
  
  /// Update member activity (last active timestamp, message count, engagement score)
  Future<void> updateMemberActivity({
    required String groupId,
    required String cpId,
  });
}
