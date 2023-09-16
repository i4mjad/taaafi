import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/data/models/UserProfile.dart';
import 'package:reboot_app_3/repository/user_context.dart';

class UserViewModel extends StateNotifier<UserProfile> {
  final IUserContext _userContext;

  UserViewModel(this._userContext) : super(null) {
    _fetchUserProfile();
  }

  void _fetchUserProfile() {
    _userContext.userProfileStream.listen((userProfile) {
      state = userProfile;
    });
  }

  Future<void> createNewData(DateTime selectedDate,
      {String gender, String locale}) async {
    try {
      return await _userContext.createNewData(selectedDate, gender, locale);
    } catch (error) {
      print('Error creating new data: $error');

      //TODO: consider checking a prober way to display the error using a snackbar for examnple.
    }
  }

  Future<void> updateUserData(String gender, String locale) async {
    var map = {
      "gender": gender,
      "locale": locale,
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

  UserProfile getUserProfile() {
    return _userContext.getUserProfile();
  }

  Stream<UserProfile> get userProfileStream => _userContext.userProfileStream;
  Stream<DocumentSnapshot> get userDocumentStream => _userContext.getUserDoc();
}
