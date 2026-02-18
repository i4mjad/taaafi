import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';
import 'package:reboot_app_3/features/groups/domain/entities/join_result_entity.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/groups/domain/repositories/groups_repository.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/community/data/models/attachment.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';

final attachmentGroupServiceProvider = Provider<AttachmentGroupService>((ref) {
  final groupsRepository = ref.watch(groupsRepositoryProvider);
  return AttachmentGroupService(ref, groupsRepository);
});

class AttachmentGroupService {
  final Ref ref;
  final GroupsRepository _groupsRepository;
  
  AttachmentGroupService(this.ref, this._groupsRepository);

  /// Get groups where the user is currently an active member (for invite creation)
  Future<List<GroupEntity>> getUserGroupsForInvites(String cpId) async {
    try {
      // Get user's current membership
      final membership = await _groupsRepository.getCurrentMembership(cpId);
      if (membership == null) return [];

      // Get the group details
      final group = await _groupsRepository.getGroupById(membership.groupId);
      if (group == null) return [];

      // Only return groups that:
      // 1. Are active and not paused
      // 2. Have a join code (for sharing)
      // 3. User is an active member
      if (group.isActive && 
          !group.isPaused && 
          group.joinCode != null && 
          group.joinCode!.isNotEmpty &&
          membership.isActive) {
        return [group];
      }

      return [];
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return [];
    }
  }

  /// Create group invite attachment data
  Future<GroupInviteAttachment> createGroupInviteAttachment({
    required String postId,
    required String inviterCpId,
    required String groupId,
  }) async {
    try {
      // Validate that inviter is a member of the group
      final membership = await _groupsRepository.getCurrentMembership(inviterCpId);
      if (membership == null || membership.groupId != groupId || !membership.isActive) {
        throw Exception('Inviter is not an active member of the group');
      }

      // Get group details
      final group = await _groupsRepository.getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Validate group state
      if (!group.isActive || group.isPaused) {
        throw Exception('Group is not available for invites');
      }

      if (group.joinCode == null || group.joinCode!.isEmpty) {
        throw Exception('Group does not have a join code for sharing');
      }

      // Create group snapshot for the invite
      final groupSnapshot = GroupSnapshot(
        name: group.name,
        gender: group.gender,
        capacity: group.memberCapacity,
        memberCount: group.memberCount,
        joinMethod: group.joinMethod,
        plusOnly: group.memberCapacity > 6, // Groups >6 members require Plus
      );

      // Set invite expiry (7 days from now)
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      // Create attachment ID
      final attachmentId = '${DateTime.now().millisecondsSinceEpoch}_group_invite';

      return GroupInviteAttachment(
        id: attachmentId,
        schemaVersion: '1.0',
        createdAt: DateTime.now(),
        createdByCpId: inviterCpId,
        status: 'active',
        inviterCpId: inviterCpId,
        groupId: groupId,
        groupSnapshot: groupSnapshot,
        inviteJoinCode: group.joinCode!,
        expiresAt: expiresAt,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Validate group invite and attempt to join
  Future<GroupJoinResult> joinGroupFromInvite({
    required String groupId,
    required String joinCode,
    required String joinerCpId,
    required String inviteId,
  }) async {
    try {
      // Verify the invite is still valid by checking the join code
      final group = await _groupsRepository.findGroupByJoinCode(joinCode);
      if (group == null || group.id != groupId) {
        return GroupJoinResult.error(GroupJoinError.inviteExpired);
      }

      // Validate group state
      if (!group.isActive) {
        return GroupJoinResult.error(GroupJoinError.groupInactive);
      }

      if (group.isPaused) {
        return GroupJoinResult.error(GroupJoinError.groupPaused);
      }

      // Check capacity
      if (group.memberCount >= group.memberCapacity) {
        return GroupJoinResult.error(GroupJoinError.capacityFull);
      }

      // Use the existing repository join method
      final joinResult = await _groupsRepository.joinGroupWithCode(
        groupId: groupId,
        joinCode: joinCode,
        cpId: joinerCpId,
      );

      // Map the repository result to our result type
      if (joinResult.success && joinResult.membership != null) {
        return GroupJoinResult.success(joinResult.membership!);
      } else {
        return GroupJoinResult.error(
          _mapJoinErrorType(joinResult.errorType),
        );
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return GroupJoinResult.error(GroupJoinError.unknown);
    }
  }

  /// Get group invite status (for displaying current state)
  Future<GroupInviteStatus> getInviteStatus({
    required String groupId,
    required String joinCode,
    required String inviterCpId,
    required DateTime expiresAt,
  }) async {
    try {
      // Check if invite is expired
      if (DateTime.now().isAfter(expiresAt)) {
        return GroupInviteStatus.expired;
      }

      // Check if the group still exists and is active
      final group = await _groupsRepository.findGroupByJoinCode(joinCode);
      if (group == null || group.id != groupId) {
        return GroupInviteStatus.revoked;
      }

      if (!group.isActive || group.isPaused) {
        return GroupInviteStatus.revoked;
      }

      // Check if inviter is still a member
      final inviterMembership = await _groupsRepository.getCurrentMembership(inviterCpId);
      if (inviterMembership == null || 
          inviterMembership.groupId != groupId || 
          !inviterMembership.isActive) {
        return GroupInviteStatus.revoked;
      }

      // Check capacity
      if (group.memberCount >= group.memberCapacity) {
        return GroupInviteStatus.full;
      }

      return GroupInviteStatus.active;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return GroupInviteStatus.revoked;
    }
  }

  /// Map repository join error types to our error types
  GroupJoinError _mapJoinErrorType(JoinErrorType? errorType) {
    if (errorType == null) return GroupJoinError.unknown;
    
    switch (errorType) {
      case JoinErrorType.genderMismatch:
        return GroupJoinError.genderMismatch;
      case JoinErrorType.capacityFull:
        return GroupJoinError.capacityFull;
      case JoinErrorType.cooldownActive:
        return GroupJoinError.cooldown;
      case JoinErrorType.alreadyInGroup:
        return GroupJoinError.alreadyMember;
      case JoinErrorType.groupNotFound:
      case JoinErrorType.invalidCode:
      case JoinErrorType.expiredCode:
        return GroupJoinError.inviteExpired;
      case JoinErrorType.groupInactive:
        return GroupJoinError.groupInactive;
      case JoinErrorType.groupPaused:
        return GroupJoinError.groupPaused;
      case JoinErrorType.invalidJoinMethod:
        return GroupJoinError.inviteExpired;
      case JoinErrorType.userBanned:
        return GroupJoinError.unknown;
    }
  }
}

/// Result type for group join attempts
class GroupJoinResult {
  final bool success;
  final GroupMembershipEntity? membership;
  final GroupJoinError? error;

  const GroupJoinResult._({
    required this.success,
    this.membership,
    this.error,
  });

  const GroupJoinResult.success(GroupMembershipEntity membership)
      : this._(success: true, membership: membership);

  const GroupJoinResult.error(GroupJoinError error)
      : this._(success: false, error: error);
}

/// Possible group join errors
enum GroupJoinError {
  inviteExpired,
  groupInactive,
  groupPaused,
  capacityFull,
  genderMismatch,
  cooldown,
  alreadyMember,
  plusRequired,
  unknown,
}

/// Status of a group invite
enum GroupInviteStatus {
  active,
  expired,
  revoked,
  full,
}

/// Extension to get localization keys for join errors
extension GroupJoinErrorLocalization on GroupJoinError {
  String get localizationKey {
    switch (this) {
      case GroupJoinError.inviteExpired:
        return 'group-invite-expired';
      case GroupJoinError.groupInactive:
        return 'group-invite-expired';
      case GroupJoinError.groupPaused:
        return 'group-invite-expired';
      case GroupJoinError.capacityFull:
        return 'join-blocked-capacity';
      case GroupJoinError.genderMismatch:
        return 'join-blocked-gender';
      case GroupJoinError.cooldown:
        return 'join-blocked-cooldown';
      case GroupJoinError.alreadyMember:
        return 'join-blocked-cooldown'; // Generic message
      case GroupJoinError.plusRequired:
        return 'join-blocked-plus-only';
      case GroupJoinError.unknown:
        return 'generic_error';
    }
  }
}
