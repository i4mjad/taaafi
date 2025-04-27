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

      // Force a full refresh of the current user
      try {
        await _auth.currentUser?.reload();
      } catch (reloadError) {
        // If reload fails, the user might have been deleted
        ref.read(errorLoggerProvider).logException(
            reloadError, StackTrace.current,
            message: "Failed to reload user data");
        // Force sign out to clear any stale state
        await _auth.signOut();
        state = const AsyncValue.data(null);
        return null;
      }

      final currentUser = _auth.currentUser;
      final uid = currentUser?.uid;

      if (uid == null) {
        state = const AsyncValue.data(null);
        return null;
      }

      // Verify user token is still valid
      try {
        await currentUser!.getIdToken(true); // Force token refresh
      } catch (tokenError) {
        // Invalid token indicates authentication issues
        ref.read(errorLoggerProvider).logException(
            tokenError, StackTrace.current,
            message: "Invalid authentication token");

        // Force sign out to clear any invalid cached state
        await _auth.signOut();
        state = const AsyncValue.data(null);
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.server));

      if (!doc.exists) {
        // User document does not exist, but auth user does
        // This could indicate a deleted account that was recreated
        ref.read(errorLoggerProvider).logInfo(
            "User authenticated but document not found. Possible recreated account.");
        state = const AsyncValue.data(null);
        return null;
      }

      var userDocument = UserDocument.fromFirestore(doc);

      // Add additional verification - check email matches for extra security
      if (currentUser.email != null &&
          userDocument.email != null &&
          userDocument.email != currentUser.email) {
        ref.read(errorLoggerProvider).logWarning(
            "User email mismatch between auth and Firestore. Possible recreated account.",
            context: {
              'auth_email': currentUser.email,
              'firestore_email': userDocument.email,
              'uid': uid,
            });
        state = const AsyncValue.data(null);
        return null;
      }

      state = AsyncValue.data(userDocument);
      return userDocument;
    } catch (e, stack) {
      ref
          .read(errorLoggerProvider)
          .logException(e, stack, message: "Error fetching user document");
      state = AsyncValue.error(e, stack);
      return null;
    }
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

      return UserDocument.fromFirestore(doc);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  bool isLegacyUserDocument(UserDocument userDocument) {
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
        userDocument.gender == null ||
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
