import 'package:device_info_plus/device_info_plus.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
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

    await _updateUserDocument();
  }

  Future<void> _migerateFollowups(
    List<String>? relapses,
    List<String>? porns,
    List<String>? masts,
  ) async {
    //! DO SOMETHING
  }

  Future<void> _updateUserDocument() async {
    String fcmToken = await _fcmRepository.getMessagingToken();

    String deviceId = await _getDeviceId();

    String role = "user";
    // if (Platform.isAndroid) {
    //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    //   deviceInfoStr = 'Android ID: ${androidInfo.id}';
    // } else if (Platform.isIOS) {
    //   IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    //   deviceInfoStr =
    //       'iOS Identifier For Vendor: ${iosInfo.identifierForVendor}';
    // }

    // print(deviceInfoStr);
  }

  Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceInfoStr = '';
    BaseDeviceInfo deviceInfoo = await deviceInfo.iosInfo;
    return "";
  }
}
