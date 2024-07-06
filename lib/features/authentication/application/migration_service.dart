import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reboot_app_3/features/authentication/data/models/FollowUp.dart';
import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/models/new_user_document.dart';
import 'package:reboot_app_3/features/authentication/data/repos/migeration_repository.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
  final FCMRepository _fcmRepository;
  final MigerationRepository _migerationRepository;

  MigrationService(this._fcmRepository, this._migerationRepository);

  Future<void> migrateToNewDocuemntStrcture(LegacyUserDocument document) async {
    final userDoc = await _migerationRepository.getUserDocMap();

    final legacyDoc = LegacyUserDocument.fromFirestore(userDoc);

    await _migrateFollowups(
      legacyDoc.userRelapses,
      legacyDoc.userWatchingWithoutMasturbating,
      legacyDoc.userMasturbatingWithoutWatching,
    );

    await _updateUserDocument(document);
  }

  Future<void> _migrateFollowups(
    List<String>? relapses,
    List<String>? porns,
    List<String>? masts,
  ) async {
    var uuid = Uuid();

    // Convert each list to a set of DateTime strings for easy comparison
    Set<String> relapseSet = relapses?.toSet() ?? {};
    Set<String> pornSet = porns?.toSet() ?? {};
    Set<String> mastSet = masts?.toSet() ?? {};

    // Find common elements in all three lists
    Set<String> commonRelapses =
        relapseSet.intersection(pornSet).intersection(mastSet);

    // Filter out the common elements from pornSet and mastSet
    pornSet.removeAll(commonRelapses);
    mastSet.removeAll(commonRelapses);

    // Convert common elements to FollowUp with type relapse
    List<FollowUp> followUps = commonRelapses.map((timeString) {
      return FollowUp(
        id: uuid.v4(),
        time: DateTime.parse(timeString).toUtc(),
        type: FollowUpTypes.relapse.name,
      );
    }).toList();

    // Convert the remaining porn and mast lists to FollowUp objects
    followUps.addAll(pornSet.map((timeString) {
      return FollowUp(
        id: uuid.v4(),
        time: DateTime.parse(timeString).toUtc(),
        type: FollowUpTypes.pornOnly.name,
      );
    }).toList());

    followUps.addAll(mastSet.map((timeString) {
      return FollowUp(
        id: uuid.v4(),
        time: DateTime.parse(timeString).toUtc(),
        type: FollowUpTypes.mastOnly.name,
      );
    }).toList());

    await _migerationRepository.bulkFollowUpsInsertion(followUps);
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

    await _migerationRepository.updateUserDocument(newDocuemnt);
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
