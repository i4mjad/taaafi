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
}
