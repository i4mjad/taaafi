import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/messaging/fcm_topic_service.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/messaging/data/models/messaging_group.dart';
import 'package:reboot_app_3/features/messaging/data/models/user_group_membership.dart';

class MessagingGroupsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FcmTopicService _fcmTopicService;
  final Ref ref;

  MessagingGroupsRepository(
    this._firestore,
    this._auth,
    this._fcmTopicService,
    this.ref,
  );

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

      // Subscribe to FCM topic FIRST - this must succeed for consistency
      final fcmSubscriptionSuccess =
          await _fcmTopicService.subscribeToTopic(group.topicId);
      if (!fcmSubscriptionSuccess) {
        throw Exception(
            'Failed to subscribe to FCM topic: ${group.topicId}. User will not receive notifications.');
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
        // If Firestore update fails, we need to rollback the FCM subscription
        await _fcmTopicService.unsubscribeFromTopic(group.topicId);

        ref
            .read(errorLoggerProvider)
            .logException(firestoreError, firestoreStackTrace);

        // Retry once for network-related errors
        if (firestoreError.toString().contains('network') ||
            firestoreError.toString().contains('timeout') ||
            firestoreError.toString().contains('unavailable')) {
          // Re-subscribe to FCM before retry
          final retryFcmSuccess =
              await _fcmTopicService.subscribeToTopic(group.topicId);
          if (!retryFcmSuccess) {
            throw Exception(
                'Failed to re-subscribe to FCM topic during retry: ${group.topicId}');
          }

          await Future.delayed(const Duration(seconds: 1));
          await _firestore
              .collection('userGroupMemberships')
              .doc(userId)
              .set(updatedMemberships.toFirestore());
        } else {
          rethrow;
        }
      }
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

      // Update in Firestore with retry logic FIRST
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
          // If Firestore update fails, don't unsubscribe from FCM
          rethrow;
        }
      }

      // Only unsubscribe from FCM topic after Firestore update succeeds
      final fcmUnsubscriptionSuccess =
          await _fcmTopicService.unsubscribeFromTopic(topicId);
      if (!fcmUnsubscriptionSuccess) {
        // Log FCM unsubscription failure but don't fail the operation
        // Better to have extra notifications than miss important ones
        ref.read(errorLoggerProvider).logException(
              Exception('FCM unsubscription failed for topic: $topicId'),
              StackTrace.current,
            );
      }
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

  /// Sync FCM subscriptions with current user memberships
  /// Useful for data consistency and migration scenarios
  Future<bool> syncFcmSubscriptions() async {
    try {
      final subscribedTopicIds = await getSubscribedTopicIds();
      if (subscribedTopicIds.isEmpty) {
        return true; // Nothing to sync
      }

      final fcmSyncSuccess =
          await _fcmTopicService.subscribeToMultipleTopics(subscribedTopicIds);
      if (!fcmSyncSuccess) {
        ref.read(errorLoggerProvider).logException(
              Exception(
                  'Failed to sync FCM subscriptions for topics: $subscribedTopicIds'),
              StackTrace.current,
            );
      }

      return fcmSyncSuccess;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
    }
  }
}
