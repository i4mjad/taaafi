import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:reboot_app_3/data/repository/follow_up_repository.dart';
import 'package:reboot_app_3/data/web_services/firebase_service.dart';

GetIt locater = GetIt.instance;

FirebaseFirestore firestore = FirebaseFirestore.instance;
String uid = FirebaseAuth.instance.currentUser.uid;
void setupLocater() async {
  await locater.registerLazySingleton(() => FirebaseFollowUpRepository());
  await locater.registerLazySingleton(() => FirebaseService(firestore, uid));
}
