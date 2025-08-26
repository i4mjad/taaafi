import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/groups/providers/group_members_provider.dart';
import 'package:reboot_app_3/features/shared/data/notifiers/user_reports_notifier.dart';

part 'group_member_management_controller.g.dart';

/// Result class for member management operations
class MemberManagementResult {
  final bool success;
  final String? errorKey;

  const MemberManagementResult.success()
      : success = true,
        errorKey = null;
  const MemberManagementResult.error(this.errorKey) : success = false;
}

/// Controller for group member management actions
@riverpod
class GroupMemberManagementController
    extends _$GroupMemberManagementController {
  @override
  void build() {}

  /// Promote a member to admin
  Future<MemberManagementResult> promoteMemberToAdmin({
    required String groupId,
    required String memberCpId,
  }) async {
    try {
      final service = ref.read(groupsServiceProvider);
      await service.promoteMemberToAdmin(
        groupId: groupId,
        cpId: memberCpId,
      );

      // Invalidate relevant providers to refresh the UI
      _invalidateProviders(groupId);

      return const MemberManagementResult.success();
    } catch (error, stackTrace) {
      log('Error promoting member to admin: $error', stackTrace: stackTrace);
      return const MemberManagementResult.error('failed-to-promote-member');
    }
  }

  /// Demote an admin to member
  Future<MemberManagementResult> demoteMemberToMember({
    required String groupId,
    required String memberCpId,
  }) async {
    try {
      final service = ref.read(groupsServiceProvider);
      await service.demoteMemberToMember(
        groupId: groupId,
        cpId: memberCpId,
      );

      // Invalidate relevant providers to refresh the UI
      _invalidateProviders(groupId);

      return const MemberManagementResult.success();
    } catch (error, stackTrace) {
      log('Error demoting member: $error', stackTrace: stackTrace);
      return const MemberManagementResult.error('failed-to-demote-member');
    }
  }

  /// Remove a member from the group
  Future<MemberManagementResult> removeMemberFromGroup({
    required String groupId,
    required String memberCpId,
  }) async {
    try {
      final service = ref.read(groupsServiceProvider);
      await service.removeMemberFromGroup(
        groupId: groupId,
        cpId: memberCpId,
      );

      // Invalidate relevant providers to refresh the UI
      _invalidateProviders(groupId);

      return const MemberManagementResult.success();
    } catch (error, stackTrace) {
      log('Error removing member from group: $error', stackTrace: stackTrace);
      return const MemberManagementResult.error('failed-to-remove-member');
    }
  }

  /// Report a user for inappropriate behavior
  Future<MemberManagementResult> reportUser({
    required String reportedUserCpId,
    required String reportMessage,
  }) async {
    try {
      final userReportsService = ref.read(userReportsServiceProvider);

      final result = await userReportsService.submitUserReport(
        communityProfileId: reportedUserCpId,
        userMessage: reportMessage,
      );

      if (result.isSuccess) {
        return const MemberManagementResult.success();
      } else {
        return MemberManagementResult.error(
            result.errorKey ?? 'report-submission-failed');
      }
    } catch (error, stackTrace) {
      log('Error reporting user: $error', stackTrace: stackTrace);
      return const MemberManagementResult.error('report-submission-failed');
    }
  }

  /// Helper method to invalidate relevant providers after member management actions
  void _invalidateProviders(String groupId) {
    // Invalidate group members provider to refresh the members list
    ref.invalidate(groupMembersProvider(groupId));

    // Invalidate any group-related providers that might be affected
    // Add more providers here as needed based on your app's structure
  }
}
