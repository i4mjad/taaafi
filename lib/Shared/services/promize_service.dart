import 'package:reboot_app_3/core/di/container.dart';

import 'package:reboot_app_3/repository/user_context.dart';

abstract class ICustomerIOService {
  Future<void> updateUser(Map<String, dynamic> attributes);
  Future<void> checkIn(String eventName, DateTime time,
      {int relapsesStreak, int mastStreak, int pornStreak});

  Future<void> newRegisterationEvent(
      String eventName, DateTime time, DateTime startedAt);

  Future<void> createUser(String gender, String locale, DateTime dob);

  Future<void> signOut();
}

class CustomerIOService implements ICustomerIOService {
  IUserContext _userContext = getIt.get<IUserContext>();

  @override
  Future<void> updateUser(Map<String, dynamic> attributes) async {
    // CustomerIO.setProfileAttributes(attributes: attributes);
  }

  @override
  Future<void> checkIn(String eventName, DateTime time,
      {relapsesStreak = 0, int mastStreak = 0, int pornStreak = 0}) async {
    // await CustomerIO.track(name: eventName, attributes: eventAttributes);
  }

  @override
  Future<void> createUser(String gender, String locale, DateTime dob) async {
    // Map<String, Object> attributes = {
    //   ProfileAttributesConstants.Name: "",
    //   ProfileAttributesConstants.Email: profile.email,
    //   ProfileAttributesConstants.RegistrationDate:
    //       profile.creationTime.millisecondsSinceEpoch,
    //   ProfileAttributesConstants.DayOfBirth:
    //       profile.dayOfBirth.millisecondsSinceEpoch,
    //   ProfileAttributesConstants.Locale: profile.lcoale,
    //   ProfileAttributesConstants.Gender: profile.gender,
    // };

    // CustomerIO.identify(identifier: profile.uid, attributes: attributes);
  }

  @override
  Future<void> signOut() async {
    // CustomerIO.clearIdentify();
  }

  @override
  Future<void> newRegisterationEvent(
      String eventName, DateTime time, DateTime startedAt) async {
    // return CustomerIO.track(
    //     name: EventsNames.NewRegesteration, attributes: eventAttributes);
  }
}
