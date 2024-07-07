import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/authentication/data/models/new_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/migeration_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_document_provider.g.dart';

@riverpod
class NewUserDocumentNotifier extends _$NewUserDocumentNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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
        throw Exception("Document does not exist");
      }

      var map = doc.data();
      if (map == null) {
        throw Exception("Document data is null");
      }

      var newUserDocument = NewUserDocument.fromMap(map);

      state = AsyncValue.data(newUserDocument); // Update state with data
      return newUserDocument;
    } catch (e, stack) {
      print("Error fetching new user document: $e");
      state = AsyncValue.error(e, stack); // Update state with error
      return null;
    }
  }

  Future<void> createNewUserDocument(String name, DateTime dob, String gender,
      String locale, DateTime firstDate) async {
    try {
      var authService = AuthService(FCMRepository(_messaging));
      var user = await authService.getUser();
      if (user == null) {
        throw Exception("User is null");
      }

      var userDocument = await authService.createUserDocument(
          user, name, dob, gender, locale, firstDate);

      await _firestore
          .collection('users')
          .doc(userDocument.uid)
          .set(userDocument.toMap());
      state = AsyncValue.data(userDocument); // Update state with new document
    } catch (e, stack) {
      print("Error creating new user document: $e");
      state = AsyncValue.error(e, stack); // Update state with error
    }
  }
}
