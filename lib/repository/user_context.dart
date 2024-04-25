import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/data/models/UserProfile.dart';

import 'package:shared_preferences/shared_preferences.dart';

abstract class IUserContext {
  String get uid;
  Stream<DocumentSnapshot> getUserDoc();
  Future<void> createNewData(
      DateTime date, String gender, String locale, DateTime dob);

  Future<void> resetUserData(DateTime date);

  Future<void> updateUserDocument(Map<String, Object?> data);
  Stream<bool> isUserDocExist();
  Future<void> deleteUserData();
  Future<void> getLocale();
  Future<UserProfile> getUserProfile();
  Stream<UserProfile?> getUserProfileStream();
  User? getFirebaseUser();
}

class FireStoreUserContext implements IUserContext {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _userProfileController = StreamController<UserProfile?>();

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
          UserProfile userProfile = UserProfile.fromFireStore(
              _auth.currentUser!, doc.data() as Map<String, Object>);

          _userProfileController.add(userProfile);
        } else {
          _userProfileController.add(null);
        }
        return doc;
      });
    }
    throw Exception("No user is currently signed in");
  }

  @override
  Future<void> createNewData(
      DateTime date, String gender, String locale, DateTime dob) async {
    final user = _auth.currentUser;

    if (user != null) {
      final userData = {
        "uid": user.uid,
        "displayName": user.displayName,
        "userFirstDate": Timestamp.fromDate(date),
        "email": user.email,
        "gender": gender,
        "locale": locale,
        "dayOfBirth": dob,
        "userRelapses": [],
        "userMasturbatingWithoutWatching": [],
        "userWatchingWithoutMasturbating": [],
      };
      await _firestore.collection('users').doc(user.uid).set(userData);
      var doc = await _firestore.collection('users').doc(user.uid).get();
      _userProfileController.sink.add(
          UserProfile.fromFireStore(user, doc.data() as Map<String, Object>));
    } else {
      throw Exception("No user is currently signed in");
    }
  }

  @override
  Future<void> resetUserData(DateTime date) async {
    final user = _auth.currentUser;

    if (user != null) {
      final userData = {
        "userFirstDate": Timestamp.fromDate(date),
        "displayName": user.displayName,
        "userRelapses": [],
        "userMasturbatingWithoutWatching": [],
        "userWatchingWithoutMasturbating": [],
      };
      await _firestore.collection('users').doc(user.uid).update(userData);
      var doc = await _firestore.collection('users').doc(user.uid).get();
      _userProfileController.sink.add(
          UserProfile.fromFireStore(user, doc.data() as Map<String, Object>));
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

  Stream<UserProfile?> get userProfileStream => _userProfileController.stream;

  @override
  Future<UserProfile> getUserProfile() async {
    final user = _auth.currentUser;
    var docuemnt = await getUserData();
    return UserProfile.fromFireStore(user, docuemnt);
  }

  @override
  String get uid => _auth.currentUser!.uid;

  @override
  Future<String> getLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString("languageCode");
    return locale ?? ''; // Return an empty string if locale is null
  }

  @override
  Future<void> updateUserDocument(Map<String, Object?> data) async {
    final user = _auth.currentUser;
    await _firestore.collection('users').doc(user!.uid).update(data);
  }

  Future<Map<String, Object?>> getUserData() async {
    var user = _auth.currentUser;
    var document = await _firestore.collection('users').doc(user!.uid).get();

    return document.data() as Map<String, Object?>;
  }

  @override
  Stream<UserProfile?> getUserProfileStream() {
    final user = _auth.currentUser;
    final snapshot = _firestore.collection("users").doc(uid);

    snapshot.snapshots().listen((event) {
      final userProfile = UserProfile.fromFireStore(
          user!, event.data() as Map<String, dynamic>);
      _userProfileController.sink.add(userProfile);
    });

    return _userProfileController.stream;
  }

  @override
  User? getFirebaseUser() {
    return _auth.currentUser;
  }

  void dispose() {
    _userProfileController.close();
  }
}
