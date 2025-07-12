import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/services/community_service.dart';
import '../../domain/services/community_service_impl.dart';

// External dependencies
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

// Data layer
final communityRemoteDatasourceProvider =
    Provider<CommunityRemoteDatasource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CommunityRemoteDatasourceImpl(firestore);
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final remoteDatasource = ref.watch(communityRemoteDatasourceProvider);
  return CommunityRepositoryImpl(remoteDatasource);
});

// Domain layer
final communityServiceProvider = Provider<CommunityService>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return CommunityServiceImpl(repository, auth);
});
