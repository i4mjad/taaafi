import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'email_sync_service.g.dart';

class EmailSyncService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  EmailSyncService(this._auth, this._firestore);

  /// Checks if the user's email in Firestore matches their Firebase Auth email
  /// and updates it if necessary. This should be called after successful login.
  Future<void> syncUserEmailIfNeeded() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        // User not logged in, skip sync
        return;
      }

      final uid = currentUser.uid;
      final firebaseEmail = currentUser.email;

      // Skip if Firebase user doesn't have an email
      if (firebaseEmail == null || firebaseEmail.isEmpty) {
        return;
      }

      // Check if user document exists
      final docRef = _firestore.collection('users').doc(uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Document doesn't exist, skip sync
        return;
      }

      final docData = docSnapshot.data();
      if (docData == null) {
        // Document data is null, skip sync
        return;
      }

      final firestoreEmail = docData['email'] as String?;

      // Check if emails are different
      if (firestoreEmail != firebaseEmail) {
        // Update the email in Firestore
        await docRef.update({
          'email': firebaseEmail,
          'lastEmailSync': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently handle errors to avoid breaking the login flow
      // In production, you might want to log this error
      print('Email sync failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
EmailSyncService emailSyncService(EmailSyncServiceRef ref) {
  return EmailSyncService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
}
