import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_document_provider.g.dart';

@riverpod
class UserDocumentsNotifier extends _$UserDocumentsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<UserDocument?> build() async {
    print("UserDocumentsNotifier: build called");
    return await _fetchUserDocument();
  }

  Future<UserDocument?> _fetchUserDocument() async {
    int retries = 150; // Number of retries
    while (retries > 0) {
      try {
        state = const AsyncLoading(); // Indicate loading state
        print("UserDocumentsNotifier: Fetching user document");

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print(
              "UserDocumentsNotifier: User is not authenticated, retrying...");
          retries--;
          await Future.delayed(
              Duration(seconds: 1)); // Wait for a second before retrying
          continue;
        }

        final uid = user.uid;
        print("UserDocumentsNotifier: User ID is $uid");

        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          print("UserDocumentsNotifier: No document found");
          return null; // No document found
        }

        var userDocument = UserDocument.fromFirestore(doc);
        print("UserDocumentsNotifier: Document fetched successfully");
        print("UserDocumentsNotifier: ${userDocument.toString()}");

        state = AsyncValue.data(userDocument); // Update state with data
        return userDocument;
      } catch (e, stack) {
        print("UserDocumentsNotifier: Error fetching document - $e");
        state = AsyncValue.error(e, stack); // Update state with error
        return null;
      }
    }

    print("UserDocumentsNotifier: Failed to fetch user document after retries");
    state = const AsyncValue.error(
        "Failed to fetch user document after retries", StackTrace.empty);
    return null;
  }

  bool isLegacyUserDocument(UserDocument userDocument) {
    return userDocument.devicesIds == null &&
        userDocument.messagingToken == null &&
        userDocument.bookmarkedContentIds == null;
  }

  bool isNewUserDocument(UserDocument userDocument) {
    return userDocument.devicesIds != null &&
        userDocument.messagingToken != null &&
        userDocument.bookmarkedContentIds != null;
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
      final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      return data != null && !data.containsKey('devicesIds');
    } catch (e) {
      return false;
    }
  }
}
