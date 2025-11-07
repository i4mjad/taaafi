import 'dart:developer';
import '../domain/repositories/groups_repository.dart';
import '../domain/entities/group_entity.dart';

/// Service for managing group settings (capacity and details)
class GroupSettingsService {
  final GroupsRepository _repository;

  const GroupSettingsService(this._repository);

  /// Update group member capacity (admin only)
  Future<GroupEntity?> updateGroupCapacity({
    required String groupId,
    required String adminCpId,
    required int newCapacity,
  }) async {
    try {
      await _repository.updateGroupCapacity(
        groupId: groupId,
        adminCpId: adminCpId,
        newCapacity: newCapacity,
      );
      
      // Fetch and return updated group
      return await _repository.getGroupById(groupId);
    } catch (e, stackTrace) {
      log('Error in updateGroupCapacity: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update group details (name and/or description) (admin only)
  Future<GroupEntity?> updateGroupDetails({
    required String groupId,
    required String adminCpId,
    String? name,
    String? description,
  }) async {
    try {
      await _repository.updateGroupDetails(
        groupId: groupId,
        adminCpId: adminCpId,
        name: name,
        description: description,
      );
      
      // Fetch and return updated group
      return await _repository.getGroupById(groupId);
    } catch (e, stackTrace) {
      log('Error in updateGroupDetails: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get current user's group
  Future<GroupEntity?> getCurrentUserGroup(String cpId) async {
    try {
      final membership = await _repository.getCurrentMembership(cpId);
      if (membership == null) return null;
      
      return await _repository.getGroupById(membership.groupId);
    } catch (e, stackTrace) {
      log('Error in getCurrentUserGroup: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if user is admin of their group
  Future<bool> isUserGroupAdmin(String cpId) async {
    try {
      final membership = await _repository.getCurrentMembership(cpId);
      return membership?.role == 'admin';
    } catch (e, stackTrace) {
      log('Error in isUserGroupAdmin: $e', stackTrace: stackTrace);
      return false;
    }
  }
}

