import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/authentication/data/models/new_user_document.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_document_provider.g.dart';

@riverpod
class NewUserDocumentNotifier extends _$NewUserDocumentNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<NewUserDocument?> build() async {
    return await _fetchNewUserDocument();
  }

  Future<NewUserDocument?> _fetchNewUserDocument() async {
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

      var newUserDocument = NewUserDocument.fromMap(map);

      state = AsyncValue.data(newUserDocument); // Update state with data
      return newUserDocument;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack); // Update state with error
      return null;
    }
  }
}
