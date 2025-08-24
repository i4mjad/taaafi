import '../domain/repositories/groups_repository.dart';
import '../../community/domain/repositories/community_repository.dart';
import '../../community/domain/entities/community_profile_entity.dart';
import '../domain/entities/group_entity.dart';

/// Service for managing group privacy settings and user anonymity
class GroupPrivacyService {
  final GroupsRepository _groupsRepository;
  final CommunityRepository _communityRepository;

  const GroupPrivacyService(
    this._groupsRepository,
    this._communityRepository,
  );

  /// Update user's community profile anonymity setting
  Future<void> updateUserAnonymity({
    required String cpId,
    required bool isAnonymous,
  }) async {
    try {
      // Get the current community profile
      final profile = await _communityRepository.getProfile(cpId);
      if (profile == null) {
        throw Exception('Community profile not found');
      }

      // Update the profile with new anonymity setting
      final updatedProfile = profile.copyWith(
        isAnonymous: isAnonymous,
        updatedAt: DateTime.now(),
      );

      await _communityRepository.updateProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to update user anonymity: $e');
    }
  }

  /// Update group privacy settings (admin only)
  Future<GroupEntity> updateGroupPrivacySettings({
    required String groupId,
    required String adminCpId,
    String? visibility,
    String? joinMethod,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  }) async {
    try {
      // Validate admin permissions by fetching the group
      final group = await _groupsRepository.getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (group.adminCpId != adminCpId) {
        throw Exception('Only group admin can update privacy settings');
      }

      // Validate business rules
      _validatePrivacySettings(
        currentVisibility: group.visibility,
        currentJoinMethod: group.joinMethod,
        newVisibility: visibility,
        newJoinMethod: joinMethod,
      );

      // Update the group privacy settings
      await _groupsRepository.updateGroupPrivacySettings(
        groupId: groupId,
        adminCpId: adminCpId,
        visibility: visibility,
        joinMethod: joinMethod,
        joinCode: joinCode,
        joinCodeExpiresAt: joinCodeExpiresAt,
        joinCodeMaxUses: joinCodeMaxUses,
      );

      // Return the updated group
      final updatedGroup = await _groupsRepository.getGroupById(groupId);
      if (updatedGroup == null) {
        throw Exception('Failed to fetch updated group');
      }

      return updatedGroup;
    } catch (e) {
      throw Exception('Failed to update group privacy settings: $e');
    }
  }

  /// Get current group for user (to check if they're admin)
  Future<GroupEntity?> getCurrentUserGroup(String cpId) async {
    try {
      final membership = await _groupsRepository.getCurrentMembership(cpId);
      if (membership == null) return null;

      return await _groupsRepository.getGroupById(membership.groupId);
    } catch (e) {
      throw Exception('Failed to get current user group: $e');
    }
  }

  /// Check if user is admin of their current group
  Future<bool> isUserGroupAdmin(String cpId) async {
    try {
      final membership = await _groupsRepository.getCurrentMembership(cpId);
      if (membership == null) return false;

      final group = await _groupsRepository.getGroupById(membership.groupId);
      if (group == null) return false;

      return group.adminCpId == cpId;
    } catch (e) {
      return false;
    }
  }

  /// Get user's community profile
  Future<CommunityProfileEntity?> getUserCommunityProfile(String cpId) async {
    try {
      return await _communityRepository.getProfile(cpId);
    } catch (e) {
      throw Exception('Failed to get user community profile: $e');
    }
  }

  /// Validate privacy settings business rules
  void _validatePrivacySettings({
    required String currentVisibility,
    required String currentJoinMethod,
    String? newVisibility,
    String? newJoinMethod,
  }) {
    final finalVisibility = newVisibility ?? currentVisibility;
    final finalJoinMethod = newJoinMethod ?? currentJoinMethod;

    // Rule: Groups with 'any' join method must be public
    if (finalJoinMethod == 'any' && finalVisibility != 'public') {
      throw Exception('Groups with "any" join method must be public');
    }

    // Rule: Private groups cannot have 'any' join method
    if (finalVisibility == 'private' && finalJoinMethod == 'any') {
      throw Exception('Private groups cannot have "any" join method');
    }
  }
}
