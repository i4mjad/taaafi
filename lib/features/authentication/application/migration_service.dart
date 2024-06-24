import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/authentication/data/models/legacy_user_document.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'migration_service.g.dart';

@riverpod
FirebaseFirestore firestoreInstance(ref) {
  return FirebaseFirestore.instance;
}

class MigrationService {
  //TODO: here we will migerate to the new document strcture, this will include the folloiwng:
  //  1- add the new information (defined in the UML)
  //  2- move the followups from the list to a new collection called follwups
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  MigrationService(this._firestore, this._firebaseAuth);

  Future<void> migrateToNewDocuemntStrcture(LegacyUserDocument document) async {
    inspect(document);
  }
}

@riverpod
MigrationService migrationService(ref) {
  return MigrationService(
      ref.watch(firestoreInstanceProvider), ref.watch(firebaseAuthProvider));
}
