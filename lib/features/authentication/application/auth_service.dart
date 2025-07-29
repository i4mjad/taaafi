import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/core/services/email_sync_service.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/migeration_repository.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_repository.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/core/routing/app_startup.dart';
import 'package:reboot_app_3/features/vault/presentation/notifiers/streak_display_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(fcmRepositoryProvider),
    ref,
  );
}

class AuthService {
  final FirebaseAuth _auth;
  final AuthRepository _authRepository;
  final FCMRepository _fcmRepository;
  final Ref ref;

  AuthService(this._auth, this._authRepository, this._fcmRepository, this.ref);

  /// Invalidate app startup to trigger security re-check after login
  void _invalidateAppStartup() {
    try {
      ref.invalidate(appStartupProvider);
    } catch (e) {}
  }

  Future<void> signUpWithEmail(
    BuildContext context,
    String email,
    String password,
    String name,
    DateTime dob,
    String gender,
    String locale,
    DateTime firstDate,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification immediately after account creation
      if (credential.user != null && !credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }

      final fcmToken = await _fcmRepository.getMessagingToken();
      final deviceId = await _getDeviceId();

      await _authRepository.creatUserDocuemnt(
        context,
        credential.user,
        name,
        dob,
        gender,
        locale,
        firstDate,
        fcmToken,
        deviceId,
      );

      // Invalidate startup to re-check security for new user
      if (credential.user != null) {
        _invalidateAppStartup();
      }
    } on FirebaseAuthException catch (e) {
      getSnackBar(context, e.code);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(
        context,
        e.toString(),
      );
    }
  }

  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceInfoStr = '';
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceInfoStr = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceInfoStr = iosInfo.identifierForVendor != null
            ? iosInfo.identifierForVendor as String
            : "";
      }
      return deviceInfoStr;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return '';
    }
  }

  /// Performs post-login tasks like email sync
  Future<void> _performPostLoginTasks() async {
    try {
      // Sync email if needed (similar to FCM token update)
      final emailSyncService = ref.read(emailSyncServiceProvider);
      await emailSyncService.syncUserEmailIfNeeded();
    } catch (e, stackTrace) {
      // Don't break login flow for sync errors
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      await _auth.signOut();

      final googleProvider = GoogleAuthProvider();
      // Request email scope by default.
      googleProvider.addScope('email');
      // Force account selection prompt
      googleProvider.setCustomParameters({"prompt": "select_account"});

      final userCredential = await _auth.signInWithProvider(googleProvider);
      await userCredential.user?.reload();
      final user = _auth.currentUser;

      // Perform post-login tasks if user exists
      if (user != null) {
        await _performPostLoginTasks();
        _invalidateAppStartup();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        getErrorSnackBar(context, 'email-already-in-use-different-provider');
      } else {
        getErrorSnackBar(context, e.code);
      }
      return null;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(context, e.toString());
      return null;
    }
  }

  Future<User?> signInWithApple(BuildContext context) async {
    final appleProvider = AppleAuthProvider();
    appleProvider.scopes.add("email");
    appleProvider.scopes.add("name");

    try {
      await _auth.signOut();

      final appleCredential = await _auth.signInWithProvider(appleProvider);

      await appleCredential.user?.reload();
      final user = _auth.currentUser;

      // Perform post-login tasks if user exists
      if (user != null) {
        await _performPostLoginTasks();
        // Invalidate startup to re-check security for logged in user
        _invalidateAppStartup();
      }

      return user;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(context, e.toString());
      return null;
    }
  }

  Future<User?> signInWithEmail(
    BuildContext context,
    String emailAddress,
    String password,
  ) async {
    try {
      await _auth.signOut();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      await userCredential.user?.reload();
      final user = _auth.currentUser;

      // Only check if document exists
      final docExists = await _authRepository.isUserDocumentExist();
      if (!docExists && user != null) {
        await _auth.signOut();
        getErrorSnackBar(context, "email-already-in-use-different-provider");
        return null;
      }

      // Perform post-login tasks if user exists and has document
      if (user != null && docExists) {
        await _performPostLoginTasks();
        // Invalidate startup to re-check security for logged in user
        _invalidateAppStartup();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      getSnackBar(context, e.code);
      return null;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  Future<bool> reSignInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.currentUser?.reauthenticateWithProvider(appleProvider);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      switch (e.code) {
        case 'user-cancelled':
          getErrorSnackBar(context, 'authentication-cancelled');
          break;
        case 'user-disabled':
          getErrorSnackBar(context, 'user-disabled');
          break;
        case 'requires-recent-login':
          getErrorSnackBar(context, 'requires-recent-login');
          break;
        default:
          getErrorSnackBar(context, 'authentication-failed');
      }
      return false;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'something-went-wrong');
      return false;
    }
  }

  Future<bool> reSignInWithGoogle(BuildContext context) async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      // Force account selection prompt
      googleProvider.setCustomParameters({"prompt": "select_account"});

      await _auth.currentUser?.reauthenticateWithProvider(googleProvider);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      switch (e.code) {
        case 'user-disabled':
          getErrorSnackBar(context, 'user-disabled');
          break;
        case 'requires-recent-login':
          getErrorSnackBar(context, 'requires-recent-login');
          break;
        default:
          getErrorSnackBar(context, 'authentication-failed');
      }
      return false;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'something-went-wrong');
      return false;
    }
  }

  Future<bool> reSignInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        getErrorSnackBar(context, 'user-not-found');
        return false;
      }

      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      // Show specific error messages based on Firebase Auth error codes
      switch (e.code) {
        case 'wrong-password':
          getErrorSnackBar(context, 'wrong-password');
          break;
        case 'invalid-email':
          getErrorSnackBar(context, 'invalid-email');
          break;
        case 'user-disabled':
          getErrorSnackBar(context, 'user-disabled');
          break;
        case 'user-not-found':
          getErrorSnackBar(context, 'user-not-found');
          break;
        case 'too-many-requests':
          getErrorSnackBar(context, 'too-many-requests');
          break;
        case 'invalid-credential':
          getErrorSnackBar(context, 'invalid-credential');
          break;
        case 'requires-recent-login':
          getErrorSnackBar(context, 'requires-recent-login');
          break;
        default:
          getErrorSnackBar(context, 'authentication-failed');
      }
      return false;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'something-went-wrong');
      return false;
    }
  }

  Future<void> signOut(BuildContext context, WidgetRef ref) async {
    try {
      await _auth.signOut();

      // ref.invalidate(userNotifierProvider);
      ref.invalidate(userDocumentsNotifierProvider);
      ref.invalidate(accountStatusProvider);
      ref.invalidate(userNotifierProvider);
      ref.invalidate(streakRepositoryProvider);
      ref.invalidate(streakNotifierProvider);
      ref.invalidate(detailedStreakInfoProvider);
      ref.invalidate(userDocumentsNotifierProvider);
      ref.invalidate(userNotifierProvider);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      final currentUser = _auth.currentUser;
      final uid = currentUser?.uid;

      // Check if user is authenticated
      if (currentUser == null || uid == null) {
        getErrorSnackBar(context, 'user-not-found');
        return;
      }

      print('DEBUG: Starting account deletion for user: $uid');

      // Log that this user has been deleted
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('deletedUsers').doc(uid).set({
        'deletedAt': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Added to deletedUsers collection');

      // Delete the user's Firestore document only if it exists
      final docExists = await _authRepository.isUserDocumentExist();
      if (docExists) {
        await _authRepository.deleteUserDocument();
        print('DEBUG: Deleted user Firestore document');
      }

      // Delete the Firebase user account - this is the critical step
      print('DEBUG: Attempting to delete Firebase Auth user');
      await currentUser.delete();
      print('DEBUG: Firebase Auth user deleted successfully');

      // IMPORTANT: Clear the cached auth state by signing out
      await _auth.signOut();
      print('DEBUG: Signed out successfully');

      // Invalidate your providers to refresh the app state
      ref.invalidate(userDocumentsNotifierProvider);
      ref.invalidate(userNotifierProvider);
      ref.invalidate(streakRepositoryProvider);
      ref.invalidate(streakNotifierProvider);

      print('DEBUG: Account deletion completed successfully');
    } on FirebaseAuthException catch (e, stackTrace) {
      print(
          'DEBUG: FirebaseAuthException during account deletion: ${e.code} - ${e.message}');
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, e.code);
      rethrow; // Let the calling code know the deletion failed
    } catch (e, stackTrace) {
      print('DEBUG: General exception during account deletion: $e');
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, 'account-deletion-failed');
      rethrow; // Let the calling code know the deletion failed
    }
  }

  Future<void> sendForgotPasswordLink(
      BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      getSnackBar(context, "password-link-has-been-sent-to");
    } on FirebaseAuthException catch (e) {
      getErrorSnackBar(context, e.code);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<User?> getUser() async {
    try {
      return await _authRepository.currentUser;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  Future<void> completeAccountRegiseration(
    BuildContext context,
    String name,
    DateTime dob,
    String gender,
    String locale,
    DateTime firstDate,
  ) async {
    try {
      final user = await _authRepository.currentUser;
      final fcmToken = await _fcmRepository.getMessagingToken();
      final deviceId = await _getDeviceId();
      await _authRepository.creatUserDocuemnt(
        context,
        user,
        name,
        dob,
        gender,
        locale,
        firstDate,
        fcmToken,
        deviceId,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }
}
