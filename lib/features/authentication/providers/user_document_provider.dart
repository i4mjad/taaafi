import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
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
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await getUserDocument(user.uid);
      } else {
        state = const AsyncValue.data(null);
      }
    });
    return await getUserDocument(_auth.currentUser?.uid ?? '');
  }

  Future<UserDocument?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.server));

      if (!doc.exists) {
        return null; // No document found
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      // Check if the document has any non-null fields
      final hasAnyData = data.values.any((value) => value != null);
      if (!hasAnyData) {
        return null;
      }

      var userDocument = UserDocument.fromFirestore(doc);
      return userDocument.uid != null ? userDocument : null;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  bool isLegacyUserDocument(UserDocument? userDocument) {
    if (userDocument == null) return false;

    // Check if all fields are null except messagingToken
    final allFieldsNull = userDocument.uid == null &&
        userDocument.devicesIds == null &&
        userDocument.displayName == null &&
        userDocument.email == null &&
        userDocument.gender == null &&
        userDocument.locale == null &&
        userDocument.dayOfBirth == null &&
        userDocument.userFirstDate == null &&
        userDocument.role == null &&
        userDocument.userRelapses == null &&
        userDocument.userMasturbatingWithoutWatching == null &&
        userDocument.userWatchingWithoutMasturbating == null;

    if (allFieldsNull) return false;

    return userDocument.devicesIds == null ||
        userDocument.messagingToken == null ||
        userDocument.role == null;
  }

  bool isNewUserDocument(UserDocument userDocument) {
    return userDocument.devicesIds != null &&
        userDocument.messagingToken != null &&
        userDocument.role != null;
  }

  bool hasMissingData(UserDocument userDocument) {
    return userDocument.displayName == null ||
        userDocument.email == null ||
        userDocument.locale == null ||
        userDocument.uid == null ||
        userDocument.dayOfBirth == null ||
        userDocument.userFirstDate == null;
  }

  Future<bool> hasOldStructure() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = UserDocument.fromFirestore(doc);

    return data != null && data.role == null;
  }
}
