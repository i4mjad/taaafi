import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:reboot_app_3/data/models/UserProfile.dart';
import 'package:reboot_app_3/repository/user_context.dart';
import 'package:reboot_app_3/shared/constants/customer_io_attributes_const.dart';
import 'package:reboot_app_3/shared/services/promize_service.dart';

class UserViewModel extends StateNotifier<UserProfile> {
  final IUserContext _userContext;
  final ICustomerIOService _promizeService;

  UserViewModel()
      : _userContext = GetIt.I<IUserContext>(),
        _promizeService = GetIt.I<ICustomerIOService>(),
        super(UserProfile.Missing) {
    _userContext.getUserProfileStream().listen((userProfile) {
      state = userProfile;
    });
  }

  Future<void> createNewData(DateTime selectedDate,
      {String gender, String locale, DateTime dob}) async {
    try {
      await _promizeService.newRegisterationEvent(
          EventsNames.NewRegesteration, DateTime.now(), selectedDate);
      return await _userContext.createNewData(
          selectedDate, gender, locale, dob);
    } catch (error) {
      print('Error creating new data: $error');

      //TODO: consider checking a prober way to display the error using a snackbar for examnple.
    }
  }

  Future<void> resetUserData(DateTime selectedDate) async {
    try {
      await _promizeService.newRegisterationEvent(
          EventsNames.NewRegesteration, DateTime.now(), selectedDate);
      return await _userContext.resetUserData(selectedDate);
    } catch (error) {
      print('Error creating new data: $error');

      //TODO: consider checking a prober way to display the error using a snackbar for examnple.
    }
  }

  Future<void> updateUserData(
      String gender, String locale, DateTime dob) async {
    final user = _userContext.getFirebaseUser();
    var map = {
      "gender": gender,
      "locale": locale,
      "dayOfBirth": dob,
      "displayName": user.displayName,
    };
    try {
      return await _userContext.updateUserDocument(map);
    } catch (error) {
      print('Error creating new data: $error');
    }
  }

  Stream<bool> isUserDocExist() {
    return _userContext.isUserDocExist();
  }

  Stream<DocumentSnapshot> getUserDoc() {
    return _userContext.getUserDoc();
  }

  Future<void> deleteUserData() {
    return _userContext.deleteUserData();
  }

  Future<UserProfile> getUserProfile() {
    return _userContext.getUserProfile();
  }

  Stream<UserProfile> get userProfileStream => _userContext.userProfileStream;
  Stream<DocumentSnapshot> get userDocumentStream => _userContext.getUserDoc();
}
