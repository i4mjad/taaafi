import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/models/new_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repos/migeration_repository.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'migration_service.g.dart';

@riverpod
FirebaseFirestore firestoreInstance(ref) {
  return FirebaseFirestore.instance;
}

@riverpod
FirebaseMessaging messagingInstance(ref) {
  return FirebaseMessaging.instance;
}

@riverpod
MigrationService migrationService(ref) {
  return MigrationService(
    ref.watch(fcmRepositoryProvider),
    ref.watch(migerationRepositoryProvider),
  );
}

class MigrationService {
  //  1- add the new information (defined in the UML)
  //  2- move the followups from the list to a new collection called follwups

  final FCMRepository _fcmRepository;
  final MigerationRepository _migerationRepository;

  MigrationService(this._fcmRepository, this._migerationRepository);

  Future<void> migrateToNewDocuemntStrcture(LegacyUserDocument document) async {
    final userDoc = await _migerationRepository.getUserDocMap();

    final legacyDoc = LegacyUserDocument.fromFirestore(userDoc);

    await _migerateFollowups(
      legacyDoc.userRelapses,
      legacyDoc.userWatchingWithoutMasturbating,
      legacyDoc.userMasturbatingWithoutWatching,
    );

    await _updateUserDocument(document);
  }

  Future<void> _migerateFollowups(
    List<String>? relapses,
    List<String>? porns,
    List<String>? masts,
  ) async {
    // Convert the three lists to be lists of List<FollowUp>
    // Merge the lists to be in one list of List<FollowUp>
    // add the lists to the followup collection
  }

  Future<void> _updateUserDocument(LegacyUserDocument document) async {
    String fcmToken = await _fcmRepository.getMessagingToken();

    var deviceId = await _getDeviceId();

    String role = "user";
    NewUserDocument newDocuemnt = NewUserDocument(
      uid: document.uid!,
      devicesIds: [deviceId],
      displayName: document.displayName!,
      email: document.email!,
      gender: document.gender!,
      locale: document.locale!,
      dayOfBirth: document.dayOfBirth!,
      userFirstDate: document.userFirstDate!,
      role: role,
      messagingToken: fcmToken,
      bookmarkedContentIds: [],
    );

    inspect(newDocuemnt);
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
