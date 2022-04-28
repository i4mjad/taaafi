
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/data/follow_up_repository.dart';
import 'package:reboot_app_3/data/models/user_profile.dart';
import 'package:reboot_app_3/data/web_services/firebase_service.dart';

class FirebaseFollowUpRepository implements FollowUpRepository {
  FirebaseService _firebaseService = FirebaseService('users');
  String userUid = FirebaseAuth.instance.currentUser.uid;

  @override
  Stream<FollowUpData> relapses() {
    return _firebaseService.getDocumentById(userUid).then((snapshot) {
      print(snapshot.data());
      return FollowUpData.fromSnapshot(snapshot.data());
    }).asStream();
  }
}
