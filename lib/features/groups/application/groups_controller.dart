import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/group_entity.dart';
import '../domain/entities/group_membership_entity.dart';
import '../domain/entities/join_result_entity.dart';

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
    state = const AsyncValue.loading();

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
        // Refresh membership provider after successful creation
        ref.invalidate(currentGroupMembershipProvider);
        state = const AsyncValue.data(null);
      } else {
        state = const AsyncValue.data(null);
      }

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
    state = const AsyncValue.loading();

    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.joinGroupDirectly(
        groupId: groupId,
        cpId: cpId,
      );

      if (result.success) {
        // Refresh membership provider after successful join
        ref.invalidate(currentGroupMembershipProvider);
        state = const AsyncValue.data(null);
      } else {
        state = const AsyncValue.data(null);
      }

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
    state = const AsyncValue.loading();

    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.joinGroupWithCode(
        groupId: groupId,
        joinCode: joinCode,
        cpId: cpId,
      );

      if (result.success) {
        // Refresh membership provider after successful join
        ref.invalidate(currentGroupMembershipProvider);
        state = const AsyncValue.data(null);
      } else {
        state = const AsyncValue.data(null);
      }

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
    state = const AsyncValue.loading();

    try {
      final service = ref.read(groupsServiceProvider);
      final result = await service.leaveGroup(cpId: cpId);

      if (result.success) {
        // Refresh membership provider after leaving
        ref.invalidate(currentGroupMembershipProvider);
        state = const AsyncValue.data(null);
      } else {
        state = const AsyncValue.data(null);
      }

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return const LeaveResultEntity.error('Unexpected error occurred');
    }
  }
}

/// Provider for current user's group membership
@riverpod
Future<GroupMembershipEntity?> currentGroupMembership(ref, String cpId) async {
  final service = ref.read(groupsServiceProvider);
  return await service.getCurrentMembership(cpId);
}

/// Provider for public groups stream
@riverpod
Stream<List<GroupEntity>> publicGroups(ref) {
  final service = ref.read(groupsServiceProvider);
  return service.getPublicGroups();
}

/// Provider to check if user can join groups
@riverpod
Future<bool> canJoinGroup(ref, String cpId) async {
  final service = ref.read(groupsServiceProvider);
  return await service.canJoinGroup(cpId);
}

/// Provider for next join allowed time
@riverpod
Future<DateTime?> nextJoinAllowedAt(ref, String cpId) async {
  final service = ref.read(groupsServiceProvider);
  return await service.getNextJoinAllowedAt(cpId);
}
