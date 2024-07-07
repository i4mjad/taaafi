import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/authentication/data/models/new_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/migeration_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(ref) {
  return AuthService(ref.watch(fcmRepositoryProvider));
}

class AuthService {
  final FCMRepository _fcmRepository;

  AuthService(this._fcmRepository);

  Future<NewUserDocument> createUserDocument(
    User user,
    String name,
    DateTime dob,
    String gender,
    String locale,
    DateTime firstDate,
  ) async {
    final fcmToken = await _fcmRepository.getMessagingToken();
    final deviceId = await _getDeviceId();
    final userDocument = NewUserDocument(
      uid: user.uid,
      devicesIds: [deviceId],
      displayName: name,
      email: user.email as String,
      gender: gender,
      locale: locale,
      dayOfBirth: Timestamp.fromDate(dob),
      userFirstDate: Timestamp.fromDate(firstDate),
      role: "user",
      messagingToken: fcmToken,
      bookmarkedContentIds: [],
    );

    return userDocument;
  }

  Future<User?> getUser() async {
    return await FirebaseAuth.instance.currentUser;
  }

  _getDeviceId() async {
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
}
