import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_repository.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_service.dart';

part 'providers.g.dart';

@riverpod
ActivityRepository activityRepository(ActivityRepositoryRef ref) {
  return ActivityRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
}

@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

@riverpod
FirebaseFirestore firestore(ref) {
  return FirebaseFirestore.instance;
}

@riverpod
ActivityService activityService(ActivityServiceRef ref) {
  return ActivityService(ref.watch(activityRepositoryProvider));
}
