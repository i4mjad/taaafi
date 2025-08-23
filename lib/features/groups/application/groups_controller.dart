import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer';
import '../domain/entities/group_entity.dart';
import '../domain/entities/group_membership_entity.dart';
import '../domain/entities/join_result_entity.dart';
import '../providers/group_membership_provider.dart';
import '../providers/groups_status_provider.dart';

import 'groups_providers.dart';

part 'groups_controller.g.dart';

/// Controller for handling group actions (join, create, leave)
@riverpod
class GroupsController extends _$GroupsController {
  @override
  FutureOr<void> build() {
    // Initial state - no async operation needed
  }

  /// Create a new group
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
    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.createGroup(
        name: name,
        description: description,
        memberCapacity: memberCapacity,
        visibility: visibility,
        joinMethod: joinMethod,
        creatorCpId: creatorCpId,
        isCreatorPlusUser: isCreatorPlusUser,
        joinCode: joinCode,
        joinCodeExpiresAt: joinCodeExpiresAt,
        joinCodeMaxUses: joinCodeMaxUses,
      );

      if (result.success) {
        // Refresh membership and status providers after successful creation
        ref.invalidate(groupMembershipNotifierProvider);
        ref.invalidate(groupsStatusProvider);
        print('GroupsController: Group created successfully, providers invalidated');
      }

      return result;
    } catch (error, stackTrace) {
      log('Error in createGroup controller: $error', stackTrace: stackTrace);
      print('GroupsController.createGroup error: $error');
      return CreateGroupResultEntity.error(
        CreateGroupErrorType.invalidName,
        'Unexpected error occurred',
      );
    }
  }

  /// Join a group directly (for public groups)
  Future<JoinResultEntity> joinGroupDirectly({
    required String groupId,
    required String cpId,
  }) async {
    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.joinGroupDirectly(
        groupId: groupId,
        cpId: cpId,
      );

      if (result.success) {
        // Refresh membership and status providers after successful join
        ref.invalidate(groupMembershipNotifierProvider);
        ref.invalidate(groupsStatusProvider);
        print('GroupsController: Joined group successfully, providers invalidated');
      }

      return result;
    } catch (error, stackTrace) {
      log('Error in joinGroupDirectly controller: $error', stackTrace: stackTrace);
      print('GroupsController.joinGroupDirectly error: $error');
      return const JoinResultEntity.error(
        JoinErrorType.groupNotFound,
        'Unexpected error occurred',
      );
    }
  }

  /// Join a group with a code
  Future<JoinResultEntity> joinGroupWithCode({
    required String groupId,
    required String joinCode,
    required String cpId,
  }) async {
    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.joinGroupWithCode(
        groupId: groupId,
        joinCode: joinCode,
        cpId: cpId,
      );

      if (result.success) {
        // Refresh membership and status providers after successful join
        ref.invalidate(groupMembershipNotifierProvider);
        ref.invalidate(groupsStatusProvider);
        print('GroupsController: Joined group with code successfully, providers invalidated');
      }

      return result;
    } catch (error, stackTrace) {
      log('Error in joinGroupWithCode controller: $error', stackTrace: stackTrace);
      print('GroupsController.joinGroupWithCode error: $error');
      return const JoinResultEntity.error(
        JoinErrorType.invalidCode,
        'Unexpected error occurred',
      );
    }
  }

  /// Leave current group
  Future<LeaveResultEntity> leaveGroup({
    required String cpId,
  }) async {
    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.leaveGroup(cpId: cpId);

      if (result.success) {
        // Refresh membership and status providers after leaving
        ref.invalidate(groupMembershipNotifierProvider);
        ref.invalidate(groupsStatusProvider);
        print('GroupsController: Left group successfully, providers invalidated');
      }

      return result;
    } catch (error, stackTrace) {
      log('Error in leaveGroup controller: $error', stackTrace: stackTrace);
      print('GroupsController.leaveGroup error: $error');
      return const LeaveResultEntity.error('Unexpected error occurred');
    }
  }
}

/// Provider for current user's group membership
@riverpod
Future<GroupMembershipEntity?> currentGroupMembership(ref, String cpId) async {
  try {
    final service = ref.read(groupsServiceProvider);
    return await service.getCurrentMembership(cpId);
  } catch (error, stackTrace) {
    log('Error in currentGroupMembership provider: $error', stackTrace: stackTrace);
    print('currentGroupMembership provider error: $error');
    rethrow;
  }
}

/// Provider for public groups stream
@riverpod
Stream<List<GroupEntity>> publicGroups(ref) {
  try {
    final service = ref.read(groupsServiceProvider);
    return service.getPublicGroups();
  } catch (error, stackTrace) {
    log('Error in publicGroups provider: $error', stackTrace: stackTrace);
    print('publicGroups provider error: $error');
    rethrow;
  }
}

/// Provider to check if user can join groups
@riverpod
Future<bool> canJoinGroup(ref, String cpId) async {
  try {
    final service = ref.read(groupsServiceProvider);
    return await service.canJoinGroup(cpId);
  } catch (error, stackTrace) {
    log('Error in canJoinGroup provider: $error', stackTrace: stackTrace);
    print('canJoinGroup provider error: $error');
    return false; // Default to false on error for safety
  }
}

/// Provider for next join allowed time
@riverpod
Future<DateTime?> nextJoinAllowedAt(ref, String cpId) async {
  try {
    final service = ref.read(groupsServiceProvider);
    return await service.getNextJoinAllowedAt(cpId);
  } catch (error, stackTrace) {
    log('Error in nextJoinAllowedAt provider: $error', stackTrace: stackTrace);
    print('nextJoinAllowedAt provider error: $error');
    return null; // Default to no restriction on error
  }
}
