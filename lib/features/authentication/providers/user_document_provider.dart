import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_document_provider.g.dart';

@riverpod
class UserDocumentNotifier extends _$UserDocumentNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<LegacyUserDocument?> build() async {
    return _fetchUserDocument();
  }

  Future<LegacyUserDocument?> _fetchUserDocument() async {
    try {
      final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      return LegacyUserDocument.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserDocument(LegacyUserDocument updatedDocument) async {
    try {
      final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;

      await _firestore
          .collection('users')
          .doc(uid)
          .set(updatedDocument.toFirestore(), SetOptions(merge: true));
      state = AsyncValue.data(updatedDocument);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> migrateUserDocument(LegacyUserDocument userDocument) async {
    try {
      // Perform migration logic here
      final updatedDocument = userDocument.copyWith(
        role: 'user', // Assuming role is removed in the new structure
        // Add any new fields or migrate data here
      );

      await updateUserDocument(updatedDocument);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> hasOldStructure() async {
    try {
      final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      print('has old strcture');
      print(data != null && data.containsKey('role'));
      // UEn9iASYDBWmDPPBXpPoOXXWTWt1
      return data != null && !data.containsKey('role');
    } catch (e) {
      return false;
    }
  }

  bool hasMissingData(LegacyUserDocument userDocument) {
    print('has missing data');
    return userDocument.displayName == null ||
        userDocument.email == null ||
        userDocument.gender == null ||
        userDocument.locale == null ||
        userDocument.uid == null ||
        userDocument.dayOfBirth == null ||
        userDocument.userFirstDate == null;
  }
}
