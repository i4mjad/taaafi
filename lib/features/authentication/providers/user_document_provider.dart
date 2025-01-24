import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_document_provider.g.dart';

@riverpod
class UserDocumentsNotifier extends _$UserDocumentsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  FutureOr<UserDocument?> build() async {
    // Listen to auth state changes and refetch user document accordingly
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserDocument();
      } else {
        state = const AsyncValue.data(null);
      }
    });
    return await _fetchUserDocument();
  }

  Future<UserDocument?> _fetchUserDocument() async {
    try {
      state = const AsyncLoading(); // Indicate loading state

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        state = AsyncValue.data(null); // Update state with error
        throw Exception("User ID is null");
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        state = AsyncValue.data(null); // Update state with error
        return null; // No document found
      }

      var userDocument = UserDocument.fromFirestore(doc);

      state = AsyncValue.data(userDocument); // Update state with data
      return userDocument;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack); // Update state with error
      return null;
    }
  }

  bool isLegacyUserDocument(UserDocument userDocument) {
    return userDocument.devicesIds == null ||
        userDocument.messagingToken == null ||
        userDocument.role == null;
  }

  bool isNewUserDocument(UserDocument userDocument) {
    return userDocument.devicesIds != null ||
        userDocument.messagingToken != null ||
        userDocument.role != null;
  }

  bool hasMissingData(UserDocument userDocument) {
    return userDocument.displayName == null ||
        userDocument.email == null ||
        userDocument.gender == null ||
        userDocument.locale == null ||
        userDocument.uid == null ||
        userDocument.dayOfBirth == null ||
        userDocument.userFirstDate == null;
  }

  Future<bool> hasOldStructure() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      return data != null && !data.containsKey('devicesIds');
    } catch (e) {
      return false;
    }
  }
}
