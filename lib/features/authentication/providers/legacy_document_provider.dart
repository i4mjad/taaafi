import 'package:firebase_auth/firebase_auth.dart';
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
    return await _fetchLegacyUserDocument();
  }

  Future<LegacyUserDocument?> _fetchLegacyUserDocument() async {
    try {
      state = const AsyncLoading(); // Indicate loading state
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception("User ID is null");
      }

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return null; // No document found
      }

      var map = doc.data();
      if (map == null) {
        return null; // No document data
      }

      var legacyUserDocument = LegacyUserDocument.fromFirestore(doc);

      
      state = AsyncValue.data(legacyUserDocument); // Update state with data
      return legacyUserDocument;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack); // Update state with error
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
