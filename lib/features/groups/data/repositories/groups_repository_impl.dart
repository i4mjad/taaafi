import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_membership_entity.dart';
import '../../domain/entities/join_result_entity.dart';
import '../../domain/repositories/groups_repository.dart';
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
      return _dataSource
          .getPublicGroups()
          .map((groups) => groups.map((g) => g.toEntity()).toList());
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
      final existingMembership = await _dataSource.getCurrentMembership(creatorCpId);
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
      
      // Hash join code if provided
      String? joinCodeHash;
      if (joinCode != null && joinCode.trim().isNotEmpty) {
        // Simple hash - should use bcrypt in production
        joinCodeHash = _hashJoinCode(joinCode.trim());
      }

      // Create group model
      final group = GroupModel(
        id: '', // Will be set by Firestore
        name: name.trim(),
        description: description.trim(),
        gender: userGender,
        memberCapacity: memberCapacity,
        adminCpId: creatorCpId,
        createdByCpId: creatorCpId,
        visibility: visibility,
        joinMethod: joinMethod,
        joinCodeHash: joinCodeHash,
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

      return CreateGroupResultEntity.success(membership.toEntity());
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

      // Check join method
      if (group.joinMethod != 'code_only') {
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
        return const LeaveResultEntity.error(null); // UI layer will handle translation based on error type
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
      return const LeaveResultEntity.error(null); // UI layer will handle translation based on error type
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

  // Helper method for hashing join codes
  // In production, use bcrypt or similar
  String _hashJoinCode(String code) {
    // Simple hash - replace with proper bcrypt implementation
    return code.hashCode.toString();
  }
}
