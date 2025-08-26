import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_membership_entity.dart';
import '../../domain/entities/join_result_entity.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../utils/join_code_generator.dart';
import '../datasources/groups_datasource.dart';
import '../models/group_model.dart';
import '../models/group_membership_model.dart';
import 'dart:developer';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsDataSource _dataSource;

  const GroupsRepositoryImpl(this._dataSource);

  @override
  Future<GroupMembershipEntity?> getCurrentMembership(String cpId) async {
    try {
      final membership = await _dataSource.getCurrentMembership(cpId);
      return membership?.toEntity();
    } catch (e, stackTrace) {
      log('Error in getCurrentMembership: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<GroupEntity?> getGroupById(String groupId) async {
    try {
      final group = await _dataSource.getGroupById(groupId);
      return group?.toEntity();
    } catch (e, stackTrace) {
      log('Error in getGroupById: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<GroupEntity>> getPublicGroups() {
    try {
      return _dataSource.getPublicGroups().asyncMap((groups) async {
        // For each group, get the real member count
        final enhancedGroups = <GroupEntity>[];

        for (final group in groups) {
          try {
            final memberCount = await _dataSource.getGroupMemberCount(group.id);

            // Create a new GroupModel with the real member count
            final enhancedGroup = GroupModel(
              id: group.id,
              name: group.name,
              description: group.description,
              gender: group.gender,
              memberCapacity: group.memberCapacity,
              memberCount: memberCount,
              adminCpId: group.adminCpId,
              createdByCpId: group.createdByCpId,
              visibility: group.visibility,
              joinMethod: group.joinMethod,
              joinCode: group.joinCode,
              joinCodeExpiresAt: group.joinCodeExpiresAt,
              joinCodeMaxUses: group.joinCodeMaxUses,
              joinCodeUseCount: group.joinCodeUseCount,
              isActive: group.isActive,
              isPaused: group.isPaused,
              pauseReason: group.pauseReason,
              createdAt: group.createdAt,
              updatedAt: group.updatedAt,
            );

            enhancedGroups.add(enhancedGroup.toEntity());
          } catch (e) {
            // If member count fetch fails, still include group with 0 count
            log('Failed to get member count for group ${group.id}: $e');
            enhancedGroups.add(group.toEntity());
          }
        }

        return enhancedGroups;
      });
    } catch (e, stackTrace) {
      log('Error in getPublicGroups: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<CreateGroupResultEntity> createGroup({
    required String name,
    required String description,
    required int memberCapacity,
    required String visibility,
    required String joinMethod,
    required String creatorCpId,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  }) async {
    try {
      // Check if user already has active membership
      final existingMembership =
          await _dataSource.getCurrentMembership(creatorCpId);
      if (existingMembership != null) {
        return const CreateGroupResultEntity.error(
          CreateGroupErrorType.alreadyInGroup,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check cooldown
      if (!await _dataSource.canJoinGroup(creatorCpId)) {
        return const CreateGroupResultEntity.error(
          CreateGroupErrorType.cooldownActive,
          null, // UI layer will handle translation based on error type
        );
      }

      // Get user data for validation
      final userGender = await _dataSource.getUserGender(creatorCpId);
      if (userGender == null) {
        return const CreateGroupResultEntity.error(
          CreateGroupErrorType.invalidGender,
          'Unable to determine user gender',
        );
      }

      final isPlus = await _dataSource.isUserPlus(creatorCpId);
      if (memberCapacity > 6 && !isPlus) {
        return const CreateGroupResultEntity.error(
          CreateGroupErrorType.capacityRequiresPlusUser,
          'Plus membership required for groups with more than 6 members',
        );
      }

      final now = DateTime.now();

      // Generate join code automatically for code_only groups
      String? generatedJoinCode;

      if (joinMethod == 'code_only') {
        // Generate a random 5-character join code
        generatedJoinCode = JoinCodeGenerator.generate();
        print('Generated join code for group: $generatedJoinCode');
      } else if (joinCode != null && joinCode.trim().isNotEmpty) {
        // Handle manual join code if provided (legacy support)
        generatedJoinCode = joinCode.trim();
      }

      // Create group model
      final group = GroupModel(
        id: '', // Will be set by Firestore
        name: name.trim(),
        description: description.trim(),
        gender: userGender,
        memberCapacity: memberCapacity,
        memberCount: 1, // Creator is the first member
        adminCpId: creatorCpId,
        createdByCpId: creatorCpId,
        visibility: visibility,
        joinMethod: joinMethod,
        joinCode: generatedJoinCode,
        joinCodeExpiresAt: joinCodeExpiresAt,
        joinCodeMaxUses: joinCodeMaxUses,
        joinCodeUseCount: 0,
        isActive: true,
        isPaused: false,
        createdAt: now,
        updatedAt: now,
      );

      // Create group
      final groupId = await _dataSource.createGroup(group);

      // Create membership for creator as admin
      final membershipId = '${groupId}_$creatorCpId';
      final membership = GroupMembershipModel(
        id: membershipId,
        groupId: groupId,
        cpId: creatorCpId,
        role: 'admin',
        isActive: true,
        joinedAt: now,
        pointsTotal: 0,
      );

      await _dataSource.createMembership(membership);

      return CreateGroupResultEntity.success(
        membership.toEntity(),
        joinCode: generatedJoinCode, // Return the generated join code
      );
    } catch (e, stackTrace) {
      log('Error in createGroup: $e', stackTrace: stackTrace);
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidName,
        null, // UI layer will handle translation based on error type
      );
    }
  }

  @override
  Future<JoinResultEntity> joinGroupDirectly({
    required String groupId,
    required String cpId,
  }) async {
    try {
      // Get group
      final group = await _dataSource.getGroupById(groupId);
      if (group == null) {
        return const JoinResultEntity.error(
          JoinErrorType.groupNotFound,
          null, // UI layer will handle translation based on error type
        );
      }

      // Validate group state
      if (!group.isActive) {
        return const JoinResultEntity.error(
          JoinErrorType.groupInactive,
          null, // UI layer will handle translation based on error type
        );
      }

      if (group.isPaused) {
        return const JoinResultEntity.error(
          JoinErrorType.groupPaused,
          'This group is currently paused',
        );
      }

      // Check join method
      if (group.joinMethod != 'any') {
        return const JoinResultEntity.error(
          JoinErrorType.invalidJoinMethod,
          'This group requires an invitation or code to join',
        );
      }

      // Check capacity
      final memberCount = await _dataSource.getGroupMemberCount(groupId);
      if (memberCount >= group.memberCapacity) {
        return const JoinResultEntity.error(
          JoinErrorType.capacityFull,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check gender match
      final userGender = await _dataSource.getUserGender(cpId);
      if (userGender != group.gender) {
        return const JoinResultEntity.error(
          JoinErrorType.genderMismatch,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check if user can join (cooldown, bans)
      if (!await _dataSource.canJoinGroup(cpId)) {
        return const JoinResultEntity.error(
          JoinErrorType.cooldownActive,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check existing membership
      final existingMembership = await _dataSource.getCurrentMembership(cpId);
      if (existingMembership != null) {
        return const JoinResultEntity.error(
          JoinErrorType.alreadyInGroup,
          null, // UI layer will handle translation based on error type
        );
      }

      // Create membership
      final membershipId = '${groupId}_$cpId';
      final membership = GroupMembershipModel(
        id: membershipId,
        groupId: groupId,
        cpId: cpId,
        role: 'member',
        isActive: true,
        joinedAt: DateTime.now(),
        pointsTotal: 0,
      );

      await _dataSource.createMembership(membership);

      return JoinResultEntity.success(membership.toEntity());
    } catch (e, stackTrace) {
      log('Error in joinGroupDirectly: $e', stackTrace: stackTrace);
      return const JoinResultEntity.error(
        JoinErrorType.groupNotFound,
        null, // UI layer will handle translation based on error type
      );
    }
  }

  @override
  Future<JoinResultEntity> joinGroupWithCode({
    required String groupId,
    required String joinCode,
    required String cpId,
  }) async {
    try {
      // Get group
      final group = await _dataSource.getGroupById(groupId);
      if (group == null) {
        return const JoinResultEntity.error(
          JoinErrorType.groupNotFound,
          null, // UI layer will handle translation based on error type
        );
      }

      // Validate group state
      if (!group.isActive) {
        return const JoinResultEntity.error(
          JoinErrorType.groupInactive,
          null, // UI layer will handle translation based on error type
        );
      }

      if (group.isPaused) {
        return const JoinResultEntity.error(
          JoinErrorType.groupPaused,
          'This group is currently paused',
        );
      }

      // Check join method - both 'code_only' and 'any' can accept join codes
      if (group.joinMethod != 'code_only' && group.joinMethod != 'any') {
        return const JoinResultEntity.error(
          JoinErrorType.invalidJoinMethod,
          'This group does not accept join codes',
        );
      }

      // Verify join code
      if (!await _dataSource.verifyJoinCode(groupId, joinCode)) {
        return const JoinResultEntity.error(
          JoinErrorType.invalidCode,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check capacity
      final memberCount = await _dataSource.getGroupMemberCount(groupId);
      if (memberCount >= group.memberCapacity) {
        return const JoinResultEntity.error(
          JoinErrorType.capacityFull,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check gender match
      final userGender = await _dataSource.getUserGender(cpId);
      if (userGender != group.gender) {
        return const JoinResultEntity.error(
          JoinErrorType.genderMismatch,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check if user can join (cooldown, bans)
      if (!await _dataSource.canJoinGroup(cpId)) {
        return const JoinResultEntity.error(
          JoinErrorType.cooldownActive,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check existing membership
      final existingMembership = await _dataSource.getCurrentMembership(cpId);
      if (existingMembership != null) {
        return const JoinResultEntity.error(
          JoinErrorType.alreadyInGroup,
          null, // UI layer will handle translation based on error type
        );
      }

      // Create membership
      final membershipId = '${groupId}_$cpId';
      final membership = GroupMembershipModel(
        id: membershipId,
        groupId: groupId,
        cpId: cpId,
        role: 'member',
        isActive: true,
        joinedAt: DateTime.now(),
        pointsTotal: 0,
      );

      await _dataSource.createMembership(membership);

      // Increment join code usage
      await _dataSource.incrementJoinCodeUsage(groupId);

      return JoinResultEntity.success(membership.toEntity());
    } catch (e, stackTrace) {
      log('Error in joinGroupWithCode: $e', stackTrace: stackTrace);
      return const JoinResultEntity.error(
        JoinErrorType.invalidCode,
        null, // UI layer will handle translation based on error type
      );
    }
  }

  @override
  Future<LeaveResultEntity> leaveGroup({required String cpId}) async {
    try {
      // Get current membership
      final membership = await _dataSource.getCurrentMembership(cpId);
      if (membership == null) {
        return const LeaveResultEntity.error(
            null); // UI layer will handle translation based on error type
      }

      final groupId = membership.groupId;

      // Get group details
      final group = await _dataSource.getGroupById(groupId);
      if (group == null) {
        return const LeaveResultEntity.error(null); // Group not found
      }

      // Check if the user is an admin
      final isUserAdmin = membership.role == 'admin';
      final isUserGroupAdmin = group.adminCpId == cpId;

      if (isUserAdmin || isUserGroupAdmin) {
        // User is admin, check if they are the only admin
        final isOnlyAdmin = await _isOnlyAdmin(groupId, cpId);
        if (isOnlyAdmin) {
          // User is the only admin, need to handle admin transition or group deletion
          await _handleAdminLeaving(groupId, cpId, group);
        }
        // If there are other admins, user can leave normally without special handling
      }

      // Update membership to inactive
      final updatedMembership = GroupMembershipModel.fromEntity(
        membership.toEntity().copyWith(
              isActive: false,
              leftAt: DateTime.now(),
            ),
      );

      await _dataSource.updateMembership(updatedMembership);

      // Set 24-hour cooldown
      final nextJoinAllowedAt = DateTime.now().add(const Duration(hours: 24));
      await _dataSource.setCooldown(cpId, nextJoinAllowedAt);

      return LeaveResultEntity.success(nextJoinAllowedAt);
    } catch (e, stackTrace) {
      log('Error in leaveGroup: $e', stackTrace: stackTrace);
      return const LeaveResultEntity.error(
          null); // UI layer will handle translation based on error type
    }
  }

  /// Check if the user is the only admin in the group
  Future<bool> _isOnlyAdmin(String groupId, String cpId) async {
    try {
      // Get all active members of the group
      final activeMembers =
          await _dataSource.getActiveGroupMembersSorted(groupId);

      // Count admins (excluding the leaving user)
      final otherAdmins = activeMembers
          .where((member) => member.cpId != cpId && member.role == 'admin')
          .toList();

      return otherAdmins.isEmpty;
    } catch (e, stackTrace) {
      log('Error in _isOnlyAdmin: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Handle the scenario when the only admin is leaving the group
  Future<void> _handleAdminLeaving(
    String groupId,
    String leavingAdminCpId,
    GroupModel group,
  ) async {
    try {
      // Get all active members of the group sorted by join date (oldest first)
      final activeMembers =
          await _dataSource.getActiveGroupMembersSorted(groupId);

      // Filter out the leaving admin
      final remainingMembers = activeMembers
          .where((member) => member.cpId != leavingAdminCpId)
          .toList();

      if (remainingMembers.isEmpty) {
        // User is the only member, mark group as inactive/deleted
        log('Group $groupId has no remaining members, marking as inactive');
        await _dataSource.markGroupAsInactive(groupId);
      } else {
        // Promote the oldest remaining member to admin
        final oldestMember =
            remainingMembers.first; // Already sorted oldest first

        log('Promoting member ${oldestMember.cpId} to admin for group $groupId (only admin leaving)');

        // Promote the member to admin role
        await _dataSource.promoteMemberToAdmin(
          groupId: groupId,
          cpId: oldestMember.cpId,
        );

        // Update the group's main admin
        await updateGroupAdmin(
          groupId: groupId,
          newAdminCpId: oldestMember.cpId,
        );

        log('Successfully promoted ${oldestMember.cpId} to admin for group $groupId');
      }
    } catch (e, stackTrace) {
      log('Error in _handleAdminLeaving: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> canJoinGroup(String cpId) async {
    return await _dataSource.canJoinGroup(cpId);
  }

  @override
  Future<DateTime?> getNextJoinAllowedAt(String cpId) async {
    return await _dataSource.getNextJoinAllowedAt(cpId);
  }

  @override
  Future<int> getGroupMemberCount(String groupId) async {
    return await _dataSource.getGroupMemberCount(groupId);
  }

  @override
  Future<List<GroupMembershipEntity>> getGroupMembers(String groupId) async {
    try {
      final memberships = await _dataSource.getGroupMembers(groupId);
      return memberships.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      log('Error in getGroupMembers: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupMembershipEntity>> getActiveGroupMembersSorted(
      String groupId) async {
    try {
      final memberships =
          await _dataSource.getActiveGroupMembersSorted(groupId);
      return memberships.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      log('Error in getActiveGroupMembersSorted: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> promoteMemberToAdmin({
    required String groupId,
    required String cpId,
  }) async {
    try {
      await _dataSource.promoteMemberToAdmin(
        groupId: groupId,
        cpId: cpId,
      );
    } catch (e, stackTrace) {
      log('Error in promoteMemberToAdmin: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> demoteMemberToMember({
    required String groupId,
    required String cpId,
  }) async {
    try {
      await _dataSource.demoteMemberToMember(
        groupId: groupId,
        cpId: cpId,
      );
    } catch (e, stackTrace) {
      log('Error in demoteMemberToMember: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String cpId,
  }) async {
    try {
      await _dataSource.removeMemberFromGroup(
        groupId: groupId,
        cpId: cpId,
      );
    } catch (e, stackTrace) {
      log('Error in removeMemberFromGroup: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateGroupAdmin({
    required String groupId,
    required String newAdminCpId,
  }) async {
    try {
      // Get the group
      final group = await _dataSource.getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }

      // Update the group's adminCpId
      final updatedGroup = GroupModel.fromEntity(
        group.toEntity().copyWith(
              adminCpId: newAdminCpId,
              updatedAt: DateTime.now(),
            ),
      );

      await _dataSource.updateGroup(updatedGroup);
    } catch (e, stackTrace) {
      log('Error in updateGroupAdmin: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> markGroupAsInactive(String groupId) async {
    try {
      await _dataSource.markGroupAsInactive(groupId);
    } catch (e, stackTrace) {
      log('Error in markGroupAsInactive: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<GroupEntity?> findGroupByJoinCode(String joinCode) async {
    try {
      final group = await _dataSource.findGroupByJoinCode(joinCode);
      return group?.toEntity();
    } catch (e, stackTrace) {
      log('Error in findGroupByJoinCode: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateGroupPrivacySettings({
    required String groupId,
    required String adminCpId,
    String? visibility,
    String? joinMethod,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  }) async {
    try {
      // Get the current group
      final currentGroup = await _dataSource.getGroupById(groupId);
      if (currentGroup == null) {
        throw Exception('Group not found: $groupId');
      }

      // Verify admin permissions
      if (currentGroup.adminCpId != adminCpId) {
        throw Exception('Only group admin can update privacy settings');
      }

      // Prepare updates
      String? newJoinCode;
      if (joinCode != null && joinCode.trim().isNotEmpty) {
        newJoinCode = joinCode.trim();
      } else if (joinMethod == 'code_only' && currentGroup.joinCode == null) {
        // Generate a new join code for code_only groups that don't have one
        newJoinCode = JoinCodeGenerator.generate();
      }

      // Validate visibility and join method combination
      if (visibility != null && joinMethod != null) {
        if (joinMethod == 'any' && visibility != 'public') {
          throw Exception('Groups with "any" join method must be public');
        }
      } else if (joinMethod == 'any' && currentGroup.visibility != 'public') {
        throw Exception('Groups with "any" join method must be public');
      } else if (visibility == 'private' && currentGroup.joinMethod == 'any') {
        throw Exception('Private groups cannot have "any" join method');
      }

      // Create updated group model
      final updatedGroup = GroupModel.fromEntity(
        currentGroup.toEntity().copyWith(
              visibility: visibility ?? currentGroup.visibility,
              joinMethod: joinMethod ?? currentGroup.joinMethod,
              joinCode: newJoinCode ?? currentGroup.joinCode,
              joinCodeExpiresAt:
                  joinCodeExpiresAt ?? currentGroup.joinCodeExpiresAt,
              joinCodeMaxUses: joinCodeMaxUses ?? currentGroup.joinCodeMaxUses,
              updatedAt: DateTime.now(),
            ),
      );

      await _dataSource.updateGroup(updatedGroup);
    } catch (e, stackTrace) {
      log('Error in updateGroupPrivacySettings: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}
