import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community_profile_entity.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/services/community_service.dart';
import '../../domain/services/community_service_impl.dart';

// =============================================================================
// EXTERNAL DEPENDENCIES
// =============================================================================

/// Provider for Firebase Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

// =============================================================================
// DATA LAYER PROVIDERS
// =============================================================================

/// Provider for community remote datasource
final communityRemoteDatasourceProvider =
    Provider<CommunityRemoteDatasource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CommunityRemoteDatasourceImpl(firestore);
});

/// Provider for community repository
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final remoteDatasource = ref.watch(communityRemoteDatasourceProvider);
  return CommunityRepositoryImpl(remoteDatasource);
});

// =============================================================================
// DOMAIN LAYER PROVIDERS
// =============================================================================

/// Provider for community service
final communityServiceProvider = Provider<CommunityService>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return CommunityServiceImpl(repository, auth);
});

// =============================================================================
// PRESENTATION LAYER PROVIDERS
// =============================================================================

/// Provider for current user's community profile
final currentCommunityProfileProvider =
    StreamProvider<CommunityProfileEntity?>((ref) {
  final service = ref.watch(communityServiceProvider);
  return service.watchProfile();
});

/// Provider to check if current user has a community profile
final hasCommunityProfileProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(communityServiceProvider);
  return service.hasProfile();
});

/// Provider to check if current user has a groups profile
/// For now, this is the same as having a community profile
final hasGroupsProfileProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(communityServiceProvider);
  return service.hasProfile();
});

/// Provider for community profile creation notifier
final communityProfileCreationProvider =
    StateNotifierProvider<CommunityProfileCreationNotifier, AsyncValue<void>>(
        (ref) {
  final service = ref.watch(communityServiceProvider);
  return CommunityProfileCreationNotifier(service);
});

/// Provider for community profile update notifier
final communityProfileUpdateProvider =
    StateNotifierProvider<CommunityProfileUpdateNotifier, AsyncValue<void>>(
        (ref) {
  final service = ref.watch(communityServiceProvider);
  return CommunityProfileUpdateNotifier(service);
});

/// Provider for community interest recording
final communityInterestProvider =
    StateNotifierProvider<CommunityInterestNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(communityServiceProvider);
  return CommunityInterestNotifier(service);
});

// =============================================================================
// NOTIFIER CLASSES
// =============================================================================

/// Notifier for community profile creation
class CommunityProfileCreationNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityService _service;

  CommunityProfileCreationNotifier(this._service)
      : super(const AsyncValue.data(null));

  /// Creates a new community profile
  Future<void> createProfile({
    required String displayName,
    required String gender,
    required bool postAnonymouslyByDefault,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.createProfile(
        displayName: displayName,
        gender: gender,
        postAnonymouslyByDefault: postAnonymouslyByDefault,
        avatarUrl: avatarUrl,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Notifier for community profile updates
class CommunityProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityService _service;

  CommunityProfileUpdateNotifier(this._service)
      : super(const AsyncValue.data(null));

  /// Updates the current user's community profile
  Future<void> updateProfile({
    String? displayName,
    String? gender,
    bool? postAnonymouslyByDefault,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateProfile(
        displayName: displayName,
        gender: gender,
        postAnonymouslyByDefault: postAnonymouslyByDefault,
        avatarUrl: avatarUrl,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Notifier for community interest recording
class CommunityInterestNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityService _service;

  CommunityInterestNotifier(this._service) : super(const AsyncValue.data(null));

  /// Records user interest in community features
  Future<void> recordInterest() async {
    state = const AsyncValue.loading();

    try {
      await _service.recordInterest();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
