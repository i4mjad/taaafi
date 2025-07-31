import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/user_document.dart';
import '../providers/user_document_provider.dart';
import '../../plus/application/subscription_service.dart';
import '../../community/domain/services/community_service.dart';
import '../../community/presentation/providers/community_providers_new.dart';

part 'user_subscription_sync_service.g.dart';

/// Service to sync user subscription status with user document and community profile
class UserSubscriptionSyncService {
  final SubscriptionService _subscriptionService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CommunityService _communityService;

  UserSubscriptionSyncService(
    this._subscriptionService,
    this._firestore,
    this._auth,
    this._communityService,
  );

  /// Update user document with current subscription status
  Future<void> updateUserSubscriptionStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('UserSubscriptionSync: No authenticated user, skipping update');
        return;
      }

      // Check current subscription status
      final isSubscriptionActive =
          await _subscriptionService.isSubscriptionActive();
      final now = Timestamp.now();

      print(
          'UserSubscriptionSync: User ${currentUser.uid} isPlusUser: $isSubscriptionActive');

      // Update user document
      await _updateUserDocument(currentUser.uid, isSubscriptionActive, now);

      // Update community profile if it exists
      await _updateCommunityProfile(isSubscriptionActive);

      print('UserSubscriptionSync: Successfully updated subscription status');
    } catch (e) {
      print('UserSubscriptionSync: Failed to update subscription status - $e');
      // Don't throw - subscription sync failure shouldn't block app startup
    }
  }

  /// Update user document in Firestore
  Future<void> _updateUserDocument(
      String uid, bool isPlusUser, Timestamp timestamp) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPlusUser': isPlusUser,
        'lastPlusCheck': timestamp,
      });
      print('UserSubscriptionSync: Updated user document for $uid');
    } catch (e) {
      // If document doesn't exist, try to set the fields using merge
      try {
        await _firestore.collection('users').doc(uid).set({
          'isPlusUser': isPlusUser,
          'lastPlusCheck': timestamp,
        }, SetOptions(merge: true));
        print('UserSubscriptionSync: Created subscription fields for $uid');
      } catch (e2) {
        print('UserSubscriptionSync: Failed to update user document - $e2');
        rethrow;
      }
    }
  }

  /// Update community profile with subscription status if it exists
  Future<void> _updateCommunityProfile(bool isPlusUser) async {
    try {
      final profile = await _communityService.getCurrentProfile();
      if (profile != null) {
        // Update the community profile with subscription status
        await _communityService.updateProfile(
          isPlusUser: isPlusUser,
        );
        print(
            'UserSubscriptionSync: Updated community profile with subscription status: $isPlusUser');
      } else {
        print('UserSubscriptionSync: No community profile found');
      }
    } catch (e) {
      print(
          'UserSubscriptionSync: Failed to check/update community profile - $e');
      // Don't throw - community profile update failure shouldn't block the process
    }
  }

  /// Check if user subscription status needs to be refreshed
  /// Returns true if last check was more than 1 hour ago or if never checked
  Future<bool> shouldRefreshSubscriptionStatus(
      UserDocument? userDocument) async {
    if (userDocument?.lastPlusCheck == null) {
      return true; // Never checked before
    }

    final lastCheck = userDocument!.lastPlusCheck!.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastCheck);

    // Refresh if last check was more than 1 hour ago
    return difference.inHours >= 1;
  }
}

@riverpod
UserSubscriptionSyncService userSubscriptionSyncService(Ref ref) {
  return UserSubscriptionSyncService(
    ref.read(subscriptionServiceProvider),
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref.read(communityServiceProvider),
  );
}

/// Provider to initialize subscription sync and update user document
@riverpod
Future<void> initializeUserSubscriptionSync(Ref ref) async {
  final syncService = ref.read(userSubscriptionSyncServiceProvider);

  // Get current user document to check if refresh is needed
  final userDocument = await ref.read(userDocumentsNotifierProvider.future);

  if (await syncService.shouldRefreshSubscriptionStatus(userDocument)) {
    await syncService.updateUserSubscriptionStatus();
  } else {
    print(
        'UserSubscriptionSync: Subscription status is up to date, skipping refresh');
  }
}
