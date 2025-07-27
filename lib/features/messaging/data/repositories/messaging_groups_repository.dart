import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/messaging/data/models/messaging_group.dart';
import 'package:reboot_app_3/features/messaging/data/models/user_group_membership.dart';

class MessagingGroupsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref ref;

  MessagingGroupsRepository(this._firestore, this._auth, this.ref);

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get all available messaging groups
  Future<List<MessagingGroup>> getAvailableGroups() async {
    try {
      // Try compound query first (requires composite index)
      final querySnapshot = await _firestore
          .collection('usersMessagingGroups')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => MessagingGroup.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);

      // If index error, fallback to simple query without orderBy
      if (e.toString().contains('index') || e.toString().contains('Index')) {
        try {
          final fallbackSnapshot = await _firestore
              .collection('usersMessagingGroups')
              .where('isActive', isEqualTo: true)
              .get();

          final groups = fallbackSnapshot.docs
              .map((doc) => MessagingGroup.fromFirestore(doc))
              .toList();

          // Sort in memory as fallback
          groups.sort((a, b) => a.name.compareTo(b.name));
          return groups;
        } catch (fallbackError, fallbackStackTrace) {
          ref
              .read(errorLoggerProvider)
              .logException(fallbackError, fallbackStackTrace);

          // Final fallback: get all groups without filtering
          try {
            final allGroupsSnapshot =
                await _firestore.collection('usersMessagingGroups').get();

            final allGroups = allGroupsSnapshot.docs
                .map((doc) => MessagingGroup.fromFirestore(doc))
                .where((group) => group.isActive) // Filter in memory
                .toList();

            allGroups.sort((a, b) => a.name.compareTo(b.name));
            return allGroups;
          } catch (finalError, finalStackTrace) {
            ref
                .read(errorLoggerProvider)
                .logException(finalError, finalStackTrace);
            return []; // Return empty list as last resort
          }
        }
      }

      // For non-index errors, return empty list
      return [];
    }
  }

  /// Stream of available messaging groups
  Stream<List<MessagingGroup>> watchAvailableGroups() {
    try {
      // Try compound query first (requires composite index)
      return _firestore
          .collection('usersMessagingGroups')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MessagingGroup.fromFirestore(doc))
              .toList())
          .handleError((error, stackTrace) {
        ref.read(errorLoggerProvider).logException(error, stackTrace);

        // On error, fallback to simple query stream
        if (error.toString().contains('index') ||
            error.toString().contains('Index')) {
          return _firestore
              .collection('usersMessagingGroups')
              .where('isActive', isEqualTo: true)
              .snapshots()
              .map((snapshot) {
            final groups = snapshot.docs
                .map((doc) => MessagingGroup.fromFirestore(doc))
                .toList();
            // Sort in memory
            groups.sort((a, b) => a.name.compareTo(b.name));
            return groups;
          });
        }

        // Return empty stream for other errors
        return Stream.value(<MessagingGroup>[]);
      });
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);

      // Fallback stream for immediate errors
      return _firestore
          .collection('usersMessagingGroups')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final groups = snapshot.docs
            .map((doc) => MessagingGroup.fromFirestore(doc))
            .toList();
        groups.sort((a, b) => a.name.compareTo(b.name));
        return groups;
      }).handleError((error, stackTrace) {
        ref.read(errorLoggerProvider).logException(error, stackTrace);
        return <MessagingGroup>[];
      });
    }
  }

  /// Get user's current group memberships
  Future<UserGroupMemberships?> getUserGroupMemberships() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final docSnapshot =
          await _firestore.collection('userGroupMemberships').doc(userId).get();

      if (docSnapshot.exists) {
        return UserGroupMemberships.fromFirestore(docSnapshot);
      }
      return UserGroupMemberships(userId: userId, groups: []);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Stream of user's group memberships
  Stream<UserGroupMemberships?> watchUserGroupMemberships() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    try {
      return _firestore
          .collection('userGroupMemberships')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        try {
          if (snapshot.exists) {
            return UserGroupMemberships.fromFirestore(snapshot);
          }
          return UserGroupMemberships(userId: userId, groups: []);
        } catch (e, stackTrace) {
          ref.read(errorLoggerProvider).logException(e, stackTrace);
          // Return empty membership on parse error
          return UserGroupMemberships(userId: userId, groups: []);
        }
      }).handleError((error, stackTrace) {
        ref.read(errorLoggerProvider).logException(error, stackTrace);
        // Return empty membership on stream error
        return UserGroupMemberships(userId: userId, groups: []);
      });
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      // Return empty membership stream on immediate error
      return Stream.value(UserGroupMemberships(userId: userId, groups: []));
    }
  }

  /// Subscribe to a messaging group
  Future<void> subscribeToGroup(MessagingGroup group) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final membership = UserGroupMembership(
        groupName: group.name,
        groupNameAr: group.nameAr,
        subscribedAt: DateTime.now(),
        topicId: group.topicId,
        updatedAt: DateTime.now(),
        userId: userId,
      );

      // Get current memberships
      final userMemberships = await getUserGroupMemberships();
      final currentGroups = userMemberships?.groups ?? [];

      // Check if already subscribed
      final isAlreadySubscribed =
          currentGroups.any((existing) => existing.topicId == group.topicId);

      if (isAlreadySubscribed) {
        throw Exception('Already subscribed to this group');
      }

      // Add new membership
      final updatedGroups = [...currentGroups, membership];
      final updatedMemberships = UserGroupMemberships(
        userId: userId,
        groups: updatedGroups,
      );

      // Update in Firestore with retry logic
      try {
        final firestoreData = updatedMemberships.toFirestore();
        await _firestore.collection('userGroupMemberships').doc(userId).set(
            firestoreData); // Use set instead of update to ensure all fields are saved
      } catch (firestoreError, firestoreStackTrace) {
        ref
            .read(errorLoggerProvider)
            .logException(firestoreError, firestoreStackTrace);

        // Retry once for network-related errors
        if (firestoreError.toString().contains('network') ||
            firestoreError.toString().contains('timeout') ||
            firestoreError.toString().contains('unavailable')) {
          await Future.delayed(const Duration(seconds: 1));
          await _firestore
              .collection('userGroupMemberships')
              .doc(userId)
              .set(updatedMemberships.toFirestore());
        } else {
          rethrow;
        }
      }

      // TODO: Subscribe to FCM topic
      // await FirebaseMessaging.instance.subscribeToTopic(group.topicId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Unsubscribe from a messaging group
  Future<void> unsubscribeFromGroup(String topicId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get current memberships
      final userMemberships = await getUserGroupMemberships();
      final currentGroups = userMemberships?.groups ?? [];

      // Remove the group
      final updatedGroups = currentGroups
          .where((membership) => membership.topicId != topicId)
          .toList();

      final updatedMemberships = UserGroupMemberships(
        userId: userId,
        groups: updatedGroups,
      );

      // Update in Firestore with retry logic
      try {
        await _firestore
            .collection('userGroupMemberships')
            .doc(userId)
            .set(updatedMemberships.toFirestore());
      } catch (firestoreError, firestoreStackTrace) {
        ref
            .read(errorLoggerProvider)
            .logException(firestoreError, firestoreStackTrace);

        // Retry once for network-related errors
        if (firestoreError.toString().contains('network') ||
            firestoreError.toString().contains('timeout') ||
            firestoreError.toString().contains('unavailable')) {
          await Future.delayed(const Duration(seconds: 1));
          await _firestore
              .collection('userGroupMemberships')
              .doc(userId)
              .set(updatedMemberships.toFirestore());
        } else {
          rethrow;
        }
      }

      // TODO: Unsubscribe from FCM topic
      // await FirebaseMessaging.instance.unsubscribeFromTopic(topicId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Check if user is subscribed to a specific group
  Future<bool> isSubscribedToGroup(String topicId) async {
    try {
      final userMemberships = await getUserGroupMemberships();
      final groups = userMemberships?.groups ?? [];

      return groups.any((membership) => membership.topicId == topicId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
    }
  }

  /// Get subscribed topic IDs for the current user
  Future<List<String>> getSubscribedTopicIds() async {
    try {
      final userMemberships = await getUserGroupMemberships();
      final groups = userMemberships?.groups ?? [];

      return groups.map((membership) => membership.topicId).toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return [];
    }
  }
}
