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
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

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
  final firestore = ref.watch(firestoreProvider);
  return CommunityServiceImpl(repository, auth, firestore);
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

/// Provider to get community profile by CPId
final communityProfileByIdProvider =
    StreamProvider.family<CommunityProfileEntity?, String>((ref, cpId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('communityProfiles')
      .doc(cpId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data() as Map<String, dynamic>;
    final profile = CommunityProfileEntity(
      id: snapshot.id,
      displayName: data['displayName'] ?? 'Unknown User',
      gender: data['gender'] ?? 'other',
      isAnonymous: data['isAnonymous'] ?? false,
      avatarUrl: data['avatarUrl'],
      isPlusUser: data['isPlusUser'] as bool?,
      shareRelapseStreaks: data['shareRelapseStreaks'] as bool? ?? false,
      currentStreakDays: data['currentStreakDays'] as int?,
      streakLastUpdated: data['streakLastUpdated'] != null
          ? (data['streakLastUpdated'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );

    return profile;
  });
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

/// Calculates the relapse streak for any user ID
final userStreakCalculatorProvider =
    FutureProvider.family<int?, String>((ref, userId) async {
  try {
    print('🏆 ============================================');
    print('🏆 STREAK CALCULATOR CALLED for user: $userId');
    print('🏆 ============================================');

    final firestore = ref.watch(firestoreProvider);

    // Step 1: Get user's first date (matching StreakRepository.getUserFirstDate)
    print('🏆 Step 1: Fetching user document for userFirstDate...');
    final userDocSnapshot =
        await firestore.collection('users').doc(userId).get();
    if (!userDocSnapshot.exists) {
      print('🏆 ❌ FAILED: User document not found for $userId');
      return null;
    }
    print('🏆 ✅ User document found');

    final userData = userDocSnapshot.data() as Map<String, dynamic>;
    print('🏆 User document keys: ${userData.keys.toList()}');

    // Use userFirstDate field (NOT createdAt) to match StreakRepository
    final userFirstDateTimestamp = userData['userFirstDate'] as Timestamp?;
    if (userFirstDateTimestamp == null) {
      print('🏆 ❌ FAILED: No userFirstDate field found');
      print('🏆 Available userData: $userData');
      return null;
    }

    final userFirstDate = userFirstDateTimestamp.toDate();
    print('🏆 ✅ User first date (userFirstDate field): $userFirstDate');

    // Step 2: Get relapse follow-ups (matching StreakRepository.readFollowUpsByType)
    print('🏆 Step 2: Fetching relapse follow-ups...');
    final followUpsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('followUps')
        .where('type', isEqualTo: FollowUpType.relapse.name)
        .get();

    print('🏆 ✅ Follow-ups query completed');
    print('🏆 Found ${followUpsSnapshot.docs.length} relapse follow-ups');

    // Convert to FollowUpModel objects and sort (matching StreakService logic)
    final relapseFollowUps = followUpsSnapshot.docs
        .map((doc) => FollowUpModel.fromDoc(doc))
        .toList();

    // Debug: Print all follow-ups
    if (relapseFollowUps.isNotEmpty) {
      print('🏆 Follow-ups details:');
      for (int i = 0; i < relapseFollowUps.length && i < 3; i++) {
        final followUp = relapseFollowUps[i];
        print(
            '🏆   - Follow-up ${i + 1}: ${followUp.time}, type: ${followUp.type.name}');
      }
    } else {
      print(
          '🏆 📝 No relapse follow-ups found - checking followUps collection...');

      // Check if followUps collection exists at all
      final allFollowUpsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('followUps')
          .limit(5)
          .get();

      print(
          '🏆 Total follow-ups in collection: ${allFollowUpsSnapshot.docs.length}');
      if (allFollowUpsSnapshot.docs.isNotEmpty) {
        print('🏆 Sample follow-ups:');
        for (final doc in allFollowUpsSnapshot.docs) {
          final data = doc.data();
          print('🏆   - Type: ${data['type']}, Time: ${data['time']}');
        }
      }
    }

    // Step 3: Calculate streak (exact same logic as StreakService.calculateRelapseStreak)
    if (relapseFollowUps.isEmpty) {
      // No relapses, calculate days since user first date
      final streakDays = DateTime.now().difference(userFirstDate).inDays;
      print(
          '🏆 🎯 RESULT: No relapses found, streak since userFirstDate: $streakDays days');
      print('🏆 ============================================');
      return streakDays;
    } else {
      // Sort by time descending and get most recent relapse
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = relapseFollowUps.first.time;

      final streakDays = DateTime.now().difference(lastFollowUpDate).inDays;
      print(
          '🏆 🎯 RESULT: Last relapse: $lastFollowUpDate, current streak: $streakDays days');
      print('🏆 ============================================');
      return streakDays;
    }
  } catch (e, stackTrace) {
    print('🏆 ❌ ERROR calculating streak for $userId: $e');
    print('🏆 Stack trace: $stackTrace');
    print('🏆 ============================================');
    return null;
  }
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
    required bool isAnonymous,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.createProfile(
        displayName: displayName,
        gender: gender,
        isAnonymous: isAnonymous,
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
    bool? isAnonymous,
    String? avatarUrl,
    bool? shareRelapseStreaks,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateProfile(
        displayName: displayName,
        gender: gender,
        isAnonymous: isAnonymous,
        avatarUrl: avatarUrl,
        shareRelapseStreaks: shareRelapseStreaks,
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
