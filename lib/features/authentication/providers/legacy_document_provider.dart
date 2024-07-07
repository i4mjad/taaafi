import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'legacy_document_provider.g.dart';

@riverpod
class LegacyDocumentNotifier extends _$LegacyDocumentNotifier {
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

  Future<bool> hasOldStructure() async {
    try {
      final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      return data != null && !data.containsKey('role');
    } catch (e) {
      return false;
    }
  }

  bool hasMissingData(LegacyUserDocument userDocument) {
    return userDocument.displayName == null ||
        userDocument.email == null ||
        userDocument.gender == null ||
        userDocument.locale == null ||
        userDocument.uid == null ||
        userDocument.dayOfBirth == null ||
        userDocument.userFirstDate == null;
  }
}
