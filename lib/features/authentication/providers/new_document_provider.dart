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
    return _fetchNewUserDocument();
  }

  Future<NewUserDocument?> _fetchNewUserDocument() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();

      return NewUserDocument.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> createNewUserDocument(String name, DateTime dob, String gender,
      String locale, DateTime firstDate) async {
    try {
      var authService = AuthService(FCMRepository(_messaging));
      var user = await authService.getUser();
      var userDocument = await authService.createUserDocument(
          user!, name, dob, gender, locale, firstDate);

      await _firestore
          .collection('users')
          .doc(userDocument.uid)
          .set(userDocument.toMap());
      state = AsyncValue.data(userDocument); // Update state
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current); // Handle error
    }
  }
}
