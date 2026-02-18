import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/account/data/models/user_profile.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_notifier.g.dart';

@riverpod
FirebaseAuth firebaseAuth(ref) {
  return FirebaseAuth.instance;
}

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<UserProfile?> build() async {
    return _fetchUserProfile();
  }

  Future<String?> _getUserId() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<UserProfile?> _fetchUserProfile() async {
    try {
      final uid = await _getUserId();
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String displayName,
    required String email,
    required String gender,
    required String locale,
    required DateTime dayOfBirth,
    required DateTime userFirstDate,
    required String role,
  }) async {
    try {
      final uid = await _getUserId();
      if (uid == null) {
        print('❌ UPDATE PROFILE: No user ID found');
        return;
      }

      print('=== UPDATING USER PROFILE ===');
      print('👤 UID: $uid');
      print('📝 Display Name: $displayName');
      print('📧 Email: $email');
      print('👥 Gender: $gender');
      print('🌍 Locale: $locale');
      print('🎂 DOB: $dayOfBirth');
      print('📅 First Date: $userFirstDate');
      print('👔 Role: $role');

      final userProfile = UserProfile(
        uid: uid,
        displayName: displayName,
        email: email,
        gender: gender,
        locale: locale,
        dayOfBirth: dayOfBirth,
        userFirstDate: userFirstDate,
        role: role,
      );

      print('📄 Profile Map to be saved:');
      final profileMap = userProfile.toMap();
      profileMap.forEach((key, value) {
        print('   - $key: $value');
      });

      // Update user document
      await _firestore
          .collection('users')
          .doc(uid)
          .set(profileMap, SetOptions(merge: true));

      print('✅ UPDATE PROFILE: Successfully saved to Firestore');

      // Also update community profile gender if it exists
      try {
        final communityService = ref.read(communityServiceProvider);
        final communityProfile = await communityService.getCurrentProfile();

        if (communityProfile != null) {
          // Only update if the gender is actually different to avoid unnecessary writes
          if (communityProfile.gender != gender.toLowerCase()) {
            await communityService.updateProfile(
              gender: gender.toLowerCase(),
            );
            print('✅ UPDATE PROFILE: Updated community profile gender to $gender');
          }
        }
      } catch (e) {
        // Don't fail the entire operation if community profile update fails
        print('⚠️ UPDATE PROFILE: Failed to update community profile gender - $e');
      }

      state = AsyncValue.data(userProfile); // Update state
      print('✅ UPDATE PROFILE: State updated successfully');
      
      // IMPORTANT: Invalidate user document provider to refresh the data
      // This ensures the account status provider gets the updated document
      print('🔄 UPDATE PROFILE: Invalidating user document provider to refresh...');
      ref.invalidate(userDocumentsNotifierProvider);
      
      // Wait a bit for Firestore to propagate the changes
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ UPDATE PROFILE: User document provider invalidated and refreshed');
    } catch (e, stackTrace) {
      print('❌ UPDATE PROFILE ERROR: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace); // Handle error
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      final uid = await _getUserId();
      if (uid == null) return;

      await _firestore.collection('users').doc(uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      state = AsyncValue.data(null); // Update state
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current); // Handle error
    }
  }

  Future<void> _deleteUserCollection(String collectionName) async {
    try {
      final uid = await _getUserId();
      if (uid == null) return;

      final collectionRef =
          _firestore.collection('users').doc(uid).collection(collectionName);
      final snapshots = await collectionRef.get();

      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current); // Handle error
    }
  }

  Future<void> deleteDailyFollowUps() async {
    try {
      await _deleteUserCollection('followUps');
      final uid = await _getUserId();
      if (uid == null) return;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current); // Handle error
    }
  }

  Future<void> deleteEmotions() async {
    await _deleteUserCollection('emotions');
  }

  Future<void> deleteAllOngoingActivities() async {
    try {
      final uid = await _getUserId();
      if (uid == null) return;

      final batch = _firestore.batch();

      // Get all ongoing activities
      final ongoingActivities = await _firestore
          .collection('users')
          .doc(uid)
          .collection('ongoing_activities')
          .get();

      // For each ongoing activity
      for (var activityDoc in ongoingActivities.docs) {
        final activityId = activityDoc.data()['activityId'] as String;

        // Delete the subscription session for this activity
        final subscriptionRef = _firestore
            .collection('activities')
            .doc(activityId)
            .collection('subscriptionSessions')
            .doc(uid);
        batch.delete(subscriptionRef);

        // Delete all scheduled tasks for this activity
        final scheduledTasksSnapshot =
            await activityDoc.reference.collection('scheduledTasks').get();

        for (var taskDoc in scheduledTasksSnapshot.docs) {
          batch.delete(taskDoc.reference);
        }

        // Delete the ongoing activity document itself
        batch.delete(activityDoc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all activities: $e');
    }
  }

  Future<void> handleUserDeletion() async {
    try {
      final uid = await _getUserId();
      if (uid == null) return;

      // Step 1: Delete all ongoing activities and their related data
      await deleteAllOngoingActivities();

      // Step 2: Delete all user data collections
      await deleteDailyFollowUps();
      await deleteEmotions();

      // Step 3: Delete the user document
      await _firestore.collection('users').doc(uid).delete();

      // Step 4: Delete the Firebase Auth user
      await FirebaseAuth.instance.currentUser?.delete();

      // Step 5: force logout
      await FirebaseAuth.instance.signOut();

      state = AsyncValue.data(null); // Update state to reflect user deletion
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow; // Rethrow to handle navigation and snackbar in the UI layer
    }
  }

  Future<void> updateUserFirstDate(DateTime dateTime) async {
    final uid = await _getUserId();
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'userFirstDate': dateTime,
    });
  }
}
