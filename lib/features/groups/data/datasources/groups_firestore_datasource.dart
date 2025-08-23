import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/group_model.dart';
import '../models/group_membership_model.dart';
import 'groups_datasource.dart';

class GroupsFirestoreDataSource implements GroupsDataSource {
  final FirebaseFirestore _firestore;

  const GroupsFirestoreDataSource(this._firestore);

  @override
  Future<GroupMembershipModel?> getCurrentMembership(String cpId) async {
    try {
      final querySnapshot = await _firestore
          .collection('group_memberships')
          .where('cpId', isEqualTo: cpId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return GroupMembershipModel.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      log('Error getting current membership: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      
      if (!doc.exists) return null;
      
      return GroupModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      log('Error getting group by ID: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<GroupModel>> getPublicGroups() {
    try {
      return _firestore
          .collection('groups')
          .where('visibility', isEqualTo: 'public')
          .where('isActive', isEqualTo: true)
          .where('isPaused', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromFirestore(doc))
              .toList());
    } catch (e, stackTrace) {
      log('Error getting public groups: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> createGroup(GroupModel group) async {
    try {
      final docRef = await _firestore.collection('groups').add(group.toFirestore());
      return docRef.id;
    } catch (e, stackTrace) {
      log('Error creating group: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> createMembership(GroupMembershipModel membership) async {
    try {
      // Use composite document ID: ${groupId}_${cpId}
      final docId = '${membership.groupId}_${membership.cpId}';
      await _firestore
          .collection('group_memberships')
          .doc(docId)
          .set(membership.toFirestore());
      return docId;
    } catch (e, stackTrace) {
      log('Error creating membership: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateMembership(GroupMembershipModel membership) async {
    try {
      await _firestore
          .collection('group_memberships')
          .doc(membership.id)
          .update(membership.toFirestore());
    } catch (e, stackTrace) {
      log('Error updating membership: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> canJoinGroup(String cpId) async {
    try {
      // Check if user has cooldown
      final nextJoinTime = await getNextJoinAllowedAt(cpId);
      if (nextJoinTime != null && DateTime.now().isBefore(nextJoinTime)) {
        return false;
      }

      // Check for active bans on groups feature
      final banQuery = await _firestore
          .collection('bans')
          .where('userId', isEqualTo: await _getUserIdFromCpId(cpId))
          .where('isActive', isEqualTo: true)
          .where('restrictedFeatures', arrayContains: 'groups')
          .limit(1)
          .get();

      if (banQuery.docs.isNotEmpty) {
        // Check if ban has expired
        final banDoc = banQuery.docs.first;
        final expiresAt = banDoc.data()['expiresAt'] as Timestamp?;
        if (expiresAt == null || DateTime.now().isBefore(expiresAt.toDate())) {
          return false;
        }
      }

      return true;
    } catch (e, stackTrace) {
      log('Error checking if user can join group: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<DateTime?> getNextJoinAllowedAt(String cpId) async {
    try {
      final cpDoc = await _firestore.collection('communityProfiles').doc(cpId).get();
      if (!cpDoc.exists) return null;

      final data = cpDoc.data()!;
      final nextJoinAllowed = data['nextJoinAllowedAt'] as Timestamp?;
      final overrideUntil = data['rejoinCooldownOverrideUntil'] as Timestamp?;

      // Check if override is active
      if (overrideUntil != null && DateTime.now().isBefore(overrideUntil.toDate())) {
        return null; // No cooldown due to override
      }

      return nextJoinAllowed?.toDate();
    } catch (e, stackTrace) {
      log('Error getting next join allowed time: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setCooldown(String cpId, DateTime nextJoinAllowedAt) async {
    try {
      await _firestore.collection('communityProfiles').doc(cpId).update({
        'nextJoinAllowedAt': Timestamp.fromDate(nextJoinAllowedAt),
      });
    } catch (e, stackTrace) {
      log('Error setting cooldown: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> verifyJoinCode(String groupId, String joinCode) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return false;

      final data = groupDoc.data()!;
      final storedHash = data['joinCodeHash'] as String?;
      final expiresAt = data['joinCodeExpiresAt'] as Timestamp?;
      final maxUses = data['joinCodeMaxUses'] as int?;
      final useCount = data['joinCodeUseCount'] as int? ?? 0;

      if (storedHash == null) return false;

      // Check expiry
      if (expiresAt != null && DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      // Check usage limit
      if (maxUses != null && useCount >= maxUses) {
        return false;
      }

      // Simple hash comparison (use bcrypt in production)
      final codeHash = joinCode.hashCode.toString();
      return codeHash == storedHash;
    } catch (e, stackTrace) {
      log('Error verifying join code: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> incrementJoinCodeUsage(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'joinCodeUseCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      log('Error incrementing join code usage: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> isUserPlus(String cpId) async {
    try {
      final cpDoc = await _firestore.collection('communityProfiles').doc(cpId).get();
      if (!cpDoc.exists) return false;

      final userUID = cpDoc.data()!['userUID'] as String;
      final userDoc = await _firestore.collection('users').doc(userUID).get();
      if (!userDoc.exists) return false;

      return userDoc.data()!['isPlusUser'] as bool? ?? false;
    } catch (e, stackTrace) {
      log('Error checking Plus status: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> getUserGender(String cpId) async {
    try {
      final cpDoc = await _firestore.collection('communityProfiles').doc(cpId).get();
      if (!cpDoc.exists) return null;

      return cpDoc.data()!['gender'] as String?;
    } catch (e, stackTrace) {
      log('Error getting user gender: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getGroupMemberCount(String groupId) async {
    try {
      final querySnapshot = await _firestore
          .collection('group_memberships')
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e, stackTrace) {
      log('Error getting group member count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Helper method to get user ID from community profile ID
  Future<String> _getUserIdFromCpId(String cpId) async {
    final cpDoc = await _firestore.collection('communityProfiles').doc(cpId).get();
    if (!cpDoc.exists) throw Exception('Community profile not found');
    return cpDoc.data()!['userUID'] as String;
  }
}
