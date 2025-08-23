import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/groups_repository.dart';
import '../domain/services/groups_service.dart';
import '../data/datasources/groups_datasource.dart';
import '../data/datasources/groups_firestore_datasource.dart';
import '../data/repositories/groups_repository_impl.dart';

part 'groups_providers.g.dart';

// External dependencies
@riverpod
FirebaseFirestore firestore(ref) => FirebaseFirestore.instance;

@riverpod
FirebaseAuth firebaseAuth(ref) => FirebaseAuth.instance;

// Data layer providers
@riverpod
GroupsDataSource groupsDataSource(ref) {
  final firestore = ref.watch(firestoreProvider);
  return GroupsFirestoreDataSource(firestore);
}

@riverpod
GroupsRepository groupsRepository(ref) {
  final dataSource = ref.watch(groupsDataSourceProvider);
  return GroupsRepositoryImpl(dataSource);
}

// Domain layer providers
@riverpod
GroupsService groupsService(ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupsService(repository);
}
