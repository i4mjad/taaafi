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

  Future<UserProfile?> _fetchUserProfile() async {
    try {
      final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await _firestore
          .collection('users')
          .doc(userProfile.uid)
          .set(userProfile.toMap(), SetOptions(merge: true));
      state = AsyncValue.data(userProfile); // Update state
    } catch (e) {
      state = AsyncValue.error(e,StackTrace.current); // Handle error
    }
  }
}
