import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/migeration_repository.dart';
import 'package:reboot_app_3/features/authentication/providers/legacy_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/new_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(fcmRepositoryProvider),
  );
}

class AuthService {
  final FirebaseAuth _auth;
  final AuthRepository _authRepository;
  final FCMRepository _fcmRepository;

  AuthService(this._auth, this._authRepository, this._fcmRepository);

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
    } catch (e) {
      getSystemSnackBar(
        context,
        e.toString(),
      );
    }
  }

  Future<String> _getDeviceId() async {
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
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      final credential = await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> signInWithEmail(
    BuildContext context,
    String emailAddress,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      getSnackBar(context, e.code);
    } catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> reSignInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.currentUser?.reauthenticateWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseAuthException catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<void> signOut(BuildContext context, WidgetRef ref) async {
    try {
      await _auth.signOut();

      ref.invalidate(userNotifierProvider);
      ref.invalidate(newUserDocumentNotifierProvider);
      ref.invalidate(legacyDocumentNotifierProvider);
    } catch (e) {}
  }

  Future<void> deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      await _authRepository.deleteUserDocument();
      await _auth.currentUser?.delete();

      ref.invalidate(userNotifierProvider);
      ref.invalidate(newUserDocumentNotifierProvider);
      ref.invalidate(legacyDocumentNotifierProvider);
    } on FirebaseAuthException catch (e) {
      getErrorSnackBar(context, e.code);
    }
  }

  Future<void> sendForgotPasswordLink(
      BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      getSnackBar(context, "password-link-has-been-sent-to", email);
    } on FirebaseAuthException catch (e) {
      getErrorSnackBar(context, e.code);
    } catch (e) {
      getSystemSnackBar(context, e.toString());
    }
  }

  Future<User?> getUser() async {
    return await _authRepository.currentUser;
  }

  Future<void> completeAccountRegiseration(
    BuildContext context,
    String name,
    DateTime dob,
    String gender,
    String locale,
    DateTime firstDate,
  ) async {
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
  }
}
