import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/data/follow_up_repository.dart';
import 'package:reboot_app_3/data/models/user_profile.dart';
import 'package:reboot_app_3/data/web_services/firebase_service.dart';

class FirebaseFollowUpRepository implements FollowUpRepository {
  FirebaseService _firebaseService = FirebaseService(
      FirebaseFirestore.instance, FirebaseAuth.instance.currentUser.uid);
  @override
  getFollowUpData() {
    _firebaseService.streamUserData().listen((event) async {
      var sh = event as DocumentSnapshot;
      return await FollowUpData.fromSnapshot(sh.data());
    });
  }
}
