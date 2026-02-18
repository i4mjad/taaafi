import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Checks if the user is an Apple user without an email address
  /// This helps identify users affected by the missing email scope issue
  Future<bool> isAppleUserWithoutEmail() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if user has Apple provider
      final hasAppleProvider = currentUser.providerData
          .any((provider) => provider.providerId == 'apple.com');

      if (!hasAppleProvider) return false;

      // Check if user has no email or empty email
      final hasNoEmail =
          currentUser.email == null || currentUser.email!.isEmpty;

      return hasNoEmail;
    } catch (e) {
      return false;
    }
  }

  /// Gets the user's authentication providers for debugging/analytics
  List<String> getUserProviders() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    return currentUser.providerData
        .map((provider) => provider.providerId)
        .toList();
  }

  /// Checks if user needs email collection (legacy Apple users)
  Future<bool> shouldPromptForEmailCollection() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Only prompt Apple users without emails
      if (!await isAppleUserWithoutEmail()) return false;

      // Check if we've already prompted this user (to avoid spam)
      final docRef = _firestore.collection('users').doc(currentUser.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) return false;

      final docData = docSnapshot.data();
      final hasBeenPrompted = docData?['emailCollectionPrompted'] == true;

      // Don't prompt if we've already prompted them
      return !hasBeenPrompted;
    } catch (e) {
      return false;
    }
  }

  /// Marks that the user has been prompted for email collection
  Future<void> markEmailCollectionPrompted() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final docRef = _firestore.collection('users').doc(currentUser.uid);
      await docRef.update({
        'emailCollectionPrompted': true,
        'emailCollectionPromptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently handle errors
    }
  }
}

@Riverpod(keepAlive: true)
EmailSyncService emailSyncService(Ref ref) {
  return EmailSyncService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
}
