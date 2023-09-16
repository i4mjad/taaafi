import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/data/models/UserProfile.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class IUserContext {
  String get uid;
  Stream<DocumentSnapshot> getUserDoc();
  Future<void> createNewData(DateTime date, String gender, String locale);
  Future<void> updateUserDocument(Map<String, dynamic> data);
  Stream<bool> isUserDocExist();
  Future<void> deleteUserData();
  Future<void> getLocale();
  UserProfile getUserProfile();
  Stream<UserProfile> get userProfileStream;
}

class FireStoreUserContext implements IUserContext {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  BehaviorSubject<UserProfile> _userProfileController;

  FireStoreUserContext() {
    _userProfileController = BehaviorSubject<UserProfile>();
  }

  @override
  Stream<DocumentSnapshot> getUserDoc() {
    final user = _auth.currentUser;

    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          UserProfile userProfile =
              UserProfile.fromFirebaseUser(_auth.currentUser);
          _userProfileController.sink.add(userProfile);
          return doc;
        } else {
          _userProfileController.sink.add(null);
          return doc;
        }
      });
    }
    throw Exception("No user is currently signed in");
  }

  @override
  Future<void> createNewData(
      DateTime date, String gender, String locale) async {
    final user = _auth.currentUser;

    if (user != null) {
      final userData = {
        "uid": user.uid,
        "userFirstDate": Timestamp.fromDate(date),
        "email": user.email,
        "gender": gender,
        "locale": locale,
        "userRelapses": [],
        "userMasturbatingWithoutWatching": [],
        "userWatchingWithoutMasturbating": [],
      };
      await _firestore.collection('users').doc(user.uid).set(userData);
      _userProfileController.sink.add(UserProfile.fromFirebaseUser(user));
    } else {
      throw Exception("No user is currently signed in");
    }
  }

  @override
  Stream<bool> isUserDocExist() {
    return getUserDoc().map((doc) => doc.exists);
  }

  @override
  Future<void> deleteUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      _userProfileController.sink.add(null);
    } else {
      throw Exception("No user is currently signed in");
    }
  }

  Stream<UserProfile> get userProfileStream => _userProfileController.stream;

  @override
  UserProfile getUserProfile() {
    final user = _auth.currentUser;
    return UserProfile.fromFirebaseUser(user);
  }

  @override
  String get uid => _auth.currentUser.uid;

  @override
  Future<void> getLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final locale = await prefs.getString("languageCode");
    return locale;
  }

  @override
  Future<void> updateUserDocument(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    await _firestore.collection('users').doc(user.uid).update(data);
  }
}
