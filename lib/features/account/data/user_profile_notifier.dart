import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/account/data/models/user_profile.dart';
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
      if (uid == null) return;

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

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userProfile.toMap(), SetOptions(merge: true));
      state = AsyncValue.data(userProfile); // Update state
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current); // Handle error
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

      await _firestore.collection('users').doc(uid).update({
        'userFirstDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current); // Handle error
    }
  }

  Future<void> deleteEmotions() async {
    await _deleteUserCollection('emotions');
  }
}
