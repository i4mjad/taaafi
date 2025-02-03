import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/migeration_repository.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/features/home/data/repos/streak_repository.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
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

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth!.accessToken,
          idToken: googleAuth.idToken,
        );

        try {
          await _auth.signOut();

          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;

          return user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            getErrorSnackBar(
                context, "email-already-in-use-different-provider");
          }
          rethrow;
        }
      }
      return null;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(context, e.toString());
      return null;
    }
  }

  Future<User?> signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.scopes.add("email");
      appleProvider.scopes.add("name");

      try {
        await _auth.signOut();

        final appleCredential = await _auth.signInWithProvider(appleProvider);
        final user = appleCredential.user;

        // Only check if document exists
        final docExists = await _authRepository.isUserDocumentExist();
        if (!docExists && user != null) {
          await _auth.signOut();
          getErrorSnackBar(context, "email-already-in-use-different-provider");
          return null;
        }

        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          getErrorSnackBar(context, "email-already-in-use-different-provider");
          return null;
        }
        rethrow;
      }
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
      final user = userCredential.user;

      // Only check if document exists
      final docExists = await _authRepository.isUserDocumentExist();
      if (!docExists && user != null) {
        await _auth.signOut();
        getErrorSnackBar(context, "email-already-in-use-different-provider");
        return null;
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

  Future<void> reSignInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.currentUser?.reauthenticateWithProvider(appleProvider);
    } on FirebaseAuthException catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> reSignInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.currentUser?.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<bool> reSignInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
    }
  }

  Future<void> signOut(BuildContext context, WidgetRef ref) async {
    try {
      await _auth.signOut();

      // ref.invalidate(userNotifierProvider);
      ref.invalidate(userDocumentsNotifierProvider);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final _firestore = FirebaseFirestore.instance;
        // Track that this user has been deleted
        await _firestore.collection('deletedUsers').doc(uid).set({
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      await _authRepository.deleteUserDocument();
      await _auth.currentUser?.delete();

      // Reset all providers
      ProviderContainer().dispose();
      ref.invalidate(userDocumentsNotifierProvider);
      ref.invalidate(userNotifierProvider);
      ref.invalidate(streakRepositoryProvider);
      ref.invalidate(streakNotifierProvider);
    } on FirebaseAuthException catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      getErrorSnackBar(context, e.code);
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
