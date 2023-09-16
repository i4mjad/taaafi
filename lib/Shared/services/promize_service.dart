import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:promize_sdk/core/event_types.dart';
import 'package:promize_sdk/core/models/user.dart';
import 'package:promize_sdk/promize_sdk.dart';
import 'package:reboot_app_3/di/container.dart';

import 'package:reboot_app_3/repository/user_context.dart';

abstract class IPromizeService {
  Future<void> updateUser(String gender, String locale, DateTime dob);
  Future<void> checkIn(String eventName, DateTime time, String status,
      int relapsesStreak, int mastStreak, int pornStreak);
  Future<void> createUser();

  Future<void> signOut();
}

class PromizeService implements IPromizeService {
  final _promizeSdk = PromizeSdk.instance;
  IUserContext _userContext = getIt.get<IUserContext>();

  @override
  Future<void> updateUser(String gender, String locale, DateTime dob) async {
    var userProfile = await _userContext.getUserProfile();

    var promizeUser = new User(
        email: userProfile.email,
        name: userProfile.displayName,
        userId: userProfile.uid,
        data: userProfile.toJson(locale, gender, dob));
    await _promizeSdk.updateUser(user: promizeUser);
  }

  @override
  Future<void> checkIn(String eventName, DateTime time, String status,
      int relapsesStreak, int mastStreak, int pornStreak) async {
    Map<String, dynamic> eventData = {
      "date": time.toString(),
      "status": status,
      "relapsesStreak": relapsesStreak,
      "masturbationStreak": mastStreak,
      "pornStreak": pornStreak
    };

    return await _promizeSdk.addEvent(
      eventName: eventName,
      eventType: EventType.event,
      eventData: eventData,
    );
  }

  @override
  Future<void> createUser() async {
    var userProfile = await _userContext.getUserProfile();

    var promizeUser = new User(
      email: userProfile.email,
      name: userProfile.displayName,
      userId: userProfile.uid,
    );
    await _promizeSdk.createUser(user: promizeUser);
  }

  @override
  Future<void> signOut() async {
    await _promizeSdk.logout();
  }
}
