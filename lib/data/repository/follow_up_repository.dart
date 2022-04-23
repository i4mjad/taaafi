import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/data/follow_up_repository.dart';
import 'package:reboot_app_3/data/web_services/firebase_service.dart';

class FirebaseFollowUpRepository implements FollowUpRepository {
  String userUid = FirebaseAuth.instance.currentUser.uid;
  FirebaseService _db = FirebaseService('users');

  @override
  Stream<List<Day>> relapses() {
    //TODO - Tobe implemented
  }
}
