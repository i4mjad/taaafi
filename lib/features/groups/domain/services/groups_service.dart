import '../entities/group_entity.dart';
import '../entities/group_membership_entity.dart';
import '../entities/join_result_entity.dart';
import '../repositories/groups_repository.dart';
import 'dart:developer';

class GroupsService {
  final GroupsRepository _repository;

  const GroupsService(this._repository);

  /// Get current user's active membership
  Future<GroupMembershipEntity?> getCurrentMembership(String cpId) async {
    try {
      return await _repository.getCurrentMembership(cpId);
    } catch (error, stackTrace) {
      log('Error in GroupsService.getCurrentMembership: $error', stackTrace: stackTrace);
      print('GroupsService.getCurrentMembership error: $error');
      rethrow;
    }
  }

  /// Get public groups for discovery
  Stream<List<GroupEntity>> getPublicGroups() {
    try {
      return _repository.getPublicGroups();
    } catch (error, stackTrace) {
      log('Error in GroupsService.getPublicGroups: $error', stackTrace: stackTrace);
      print('GroupsService.getPublicGroups error: $error');
      rethrow;
    }
  }

  /// Create a new group with business logic validation
  Future<CreateGroupResultEntity> createGroup({
    required String name,
    required String description,
    required int memberCapacity,
    required String visibility,
    required String joinMethod,
    required String creatorCpId,
    required bool isCreatorPlusUser,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  }) async {
    // Validate name length
    if (name.trim().isEmpty || name.length > 60) {
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidName,
        'Group name must be between 1 and 60 characters',
      );
    }

    // Validate description length
    if (description.length > 500) {
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidName,
        'Description must be 500 characters or less',
      );
    }

    // Validate capacity and Plus requirement
    if (memberCapacity < 1 || memberCapacity > 50) {
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidCapacity,
        'Member capacity must be between 1 and 50',
      );
    }

    if (memberCapacity > 6 && !isCreatorPlusUser) {
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.capacityRequiresPlusUser,
        'Plus membership required for groups with more than 6 members',
      );
    }

    // Validate join method constraints
    if (joinMethod == 'any' && visibility != 'public') {
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidName,
        'Groups with "any" join method must be public',
      );
    }

    try {
      // Check if user already has an active membership
      final currentMembership = await _repository.getCurrentMembership(creatorCpId);
      if (currentMembership != null) {
        return const CreateGroupResultEntity.error(
          CreateGroupErrorType.alreadyInGroup,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check cooldown
      if (!await _repository.canJoinGroup(creatorCpId)) {
        return const CreateGroupResultEntity.error(
          CreateGroupErrorType.cooldownActive,
          null, // UI layer will handle translation based on error type
        );
      }

      return await _repository.createGroup(
        name: name.trim(),
        description: description.trim(),
        memberCapacity: memberCapacity,
        visibility: visibility,
        joinMethod: joinMethod,
        creatorCpId: creatorCpId,
        joinCode: joinCode,
        joinCodeExpiresAt: joinCodeExpiresAt,
        joinCodeMaxUses: joinCodeMaxUses,
      );
    } catch (error, stackTrace) {
      log('Error in GroupsService.createGroup: $error', stackTrace: stackTrace);
      print('GroupsService.createGroup error: $error');
      return const CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidName,
        null, // UI layer will handle translation based on error type
      );
    }
  }

  /// Join a group directly (for public groups with 'any' join method)
  Future<JoinResultEntity> joinGroupDirectly({
    required String groupId,
    required String cpId,
  }) async {
    try {
      // Check if user already has an active membership
      final currentMembership = await _repository.getCurrentMembership(cpId);
      if (currentMembership != null) {
        return const JoinResultEntity.error(
          JoinErrorType.alreadyInGroup,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check cooldown
      if (!await _repository.canJoinGroup(cpId)) {
        return const JoinResultEntity.error(
          JoinErrorType.cooldownActive,
          null, // UI layer will handle translation based on error type
        );
      }

      return await _repository.joinGroupDirectly(
        groupId: groupId,
        cpId: cpId,
      );
    } catch (error, stackTrace) {
      log('Error in GroupsService.joinGroupDirectly: $error', stackTrace: stackTrace);
      print('GroupsService.joinGroupDirectly error: $error');
      return const JoinResultEntity.error(
        JoinErrorType.groupNotFound,
        null, // UI layer will handle translation based on error type
      );
    }
  }

  /// Join a group using a code
  Future<JoinResultEntity> joinGroupWithCode({
    required String groupId,
    required String joinCode,
    required String cpId,
  }) async {
    if (joinCode.trim().isEmpty) {
      return const JoinResultEntity.error(
        JoinErrorType.invalidCode,
        'Join code cannot be empty',
      );
    }

    try {
      // Check if user already has an active membership
      final currentMembership = await _repository.getCurrentMembership(cpId);
      if (currentMembership != null) {
        return const JoinResultEntity.error(
          JoinErrorType.alreadyInGroup,
          null, // UI layer will handle translation based on error type
        );
      }

      // Check cooldown
      if (!await _repository.canJoinGroup(cpId)) {
        return const JoinResultEntity.error(
          JoinErrorType.cooldownActive,
          null, // UI layer will handle translation based on error type
        );
      }

      return await _repository.joinGroupWithCode(
        groupId: groupId,
        joinCode: joinCode.trim(),
        cpId: cpId,
      );
    } catch (error, stackTrace) {
      log('Error in GroupsService.joinGroupWithCode: $error', stackTrace: stackTrace);
      print('GroupsService.joinGroupWithCode error: $error');
      return const JoinResultEntity.error(
        JoinErrorType.invalidCode,
        null, // UI layer will handle translation based on error type
      );
    }
  }

  /// Leave current group
  Future<LeaveResultEntity> leaveGroup({
    required String cpId,
  }) async {
    try {
      // Check if user has an active membership
      final currentMembership = await _repository.getCurrentMembership(cpId);
      if (currentMembership == null) {
        return const LeaveResultEntity.error(
          'You are not currently in any group',
        );
      }

      return await _repository.leaveGroup(cpId: cpId);
    } catch (error, stackTrace) {
      log('Error in GroupsService.leaveGroup: $error', stackTrace: stackTrace);
      print('GroupsService.leaveGroup error: $error');
      return const LeaveResultEntity.error(null); // UI layer will handle translation based on error type
    }
  }

  /// Check if user can join groups
  Future<bool> canJoinGroup(String cpId) async {
    try {
      return await _repository.canJoinGroup(cpId);
    } catch (error, stackTrace) {
      log('Error in GroupsService.canJoinGroup: $error', stackTrace: stackTrace);
      print('GroupsService.canJoinGroup error: $error');
      return false; // Default to false on error for safety
    }
  }

  /// Get next allowed join time for user
  Future<DateTime?> getNextJoinAllowedAt(String cpId) async {
    try {
      return await _repository.getNextJoinAllowedAt(cpId);
    } catch (error, stackTrace) {
      log('Error in GroupsService.getNextJoinAllowedAt: $error', stackTrace: stackTrace);
      print('GroupsService.getNextJoinAllowedAt error: $error');
      return null; // Default to no restriction on error
    }
  }
}
