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

/// Provider to get community profile by CPId - simplified version
/// Always returns a profile, even for missing/deleted ones
final communityProfileByIdProvider =
    StreamProvider.family<CommunityProfileEntity, String>((ref, cpId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('communityProfiles')
      .doc(cpId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      // Return a fallback profile for missing profiles
      return CommunityProfileEntity(
        id: cpId,
        userUID: 'missing-profile',
        displayName: 'Former User',
        gender: 'other',
        isAnonymous: true,
        isDeleted: false,
        avatarUrl: null,
        isPlusUser: false,
        shareRelapseStreaks: false,
        currentStreakDays: null,
        streakLastUpdated: null,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: null,
      );
    }

    final data = snapshot.data() as Map<String, dynamic>;

    return CommunityProfileEntity(
      id: snapshot.id,
      userUID: data['userUID'] ?? '',
      displayName: data['displayName'] ?? 'Unknown User',
      gender: data['gender'] ?? 'other',
      isAnonymous: data['isAnonymous'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      avatarUrl: data['avatarUrl'],
      isPlusUser: data['isPlusUser'] as bool?,
      shareRelapseStreaks: data['shareRelapseStreaks'] as bool? ?? false,
      currentStreakDays: null,
      streakLastUpdated: null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  });
});

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

/// Calculates the relapse streak for any community profile ID
final userStreakCalculatorProvider =
    FutureProvider.family<int?, String>((ref, communityProfileId) async {
  try {
    final firestore = ref.watch(firestoreProvider);

    // Step 1: Get userUID from community profile
    final profileDoc = await firestore
        .collection('communityProfiles')
        .doc(communityProfileId)
        .get();

    if (!profileDoc.exists) {
      return null;
    }

    final profileData = profileDoc.data() as Map<String, dynamic>;
    final userUID = profileData['userUID'] as String?;

    if (userUID == null) {
      return null;
    }

    // Step 2: Get user's first date (matching StreakRepository.getUserFirstDate)
    final userDocSnapshot =
        await firestore.collection('users').doc(userUID).get();
    if (!userDocSnapshot.exists) {
      return null;
    }

    final userData = userDocSnapshot.data() as Map<String, dynamic>;

    // Use userFirstDate field (NOT createdAt) to match StreakRepository
    final userFirstDateTimestamp = userData['userFirstDate'] as Timestamp?;
    if (userFirstDateTimestamp == null) {
      return null;
    }

    final userFirstDate = userFirstDateTimestamp.toDate();

    // Step 3: Get relapse follow-ups (matching StreakRepository.readFollowUpsByType)
    final followUpsSnapshot = await firestore
        .collection('users')
        .doc(userUID)
        .collection('followUps')
        .where('type', isEqualTo: FollowUpType.relapse.name)
        .get();

    // Convert to FollowUpModel objects and sort (matching StreakService logic)
    final relapseFollowUps = followUpsSnapshot.docs
        .map((doc) => FollowUpModel.fromDoc(doc))
        .toList();

    if (relapseFollowUps.isNotEmpty) {
      for (int i = 0; i < relapseFollowUps.length && i < 3; i++) {
        final followUp = relapseFollowUps[i];
      }
    } else {
      // Check if followUps collection exists at all
      final allFollowUpsSnapshot = await firestore
          .collection('users')
          .doc(userUID)
          .collection('followUps')
          .limit(5)
          .get();

      if (allFollowUpsSnapshot.docs.isNotEmpty) {
        for (final doc in allFollowUpsSnapshot.docs) {
          final data = doc.data();
        }
      }
    }

    // Step 4: Calculate streak (exact same logic as StreakService.calculateRelapseStreak)
    if (relapseFollowUps.isEmpty) {
      // No relapses, calculate days since user first date
      final streakDays = DateTime.now().difference(userFirstDate).inDays;
      return streakDays;
    } else {
      // Sort by time descending and get most recent relapse
      relapseFollowUps.sort((a, b) => b.time.compareTo(a.time));
      final lastFollowUpDate = relapseFollowUps.first.time;

      final streakDays = DateTime.now().difference(lastFollowUpDate).inDays;
      return streakDays;
    }
  } catch (e, stackTrace) {
    print('🏆 ❌ ERROR in userStreakCalculatorProvider: $e');
    print('🏆 ❌ Stack trace: $stackTrace');
    return null;
  }
});

/// Community screen state enum
enum CommunityScreenState {
  loading,
  needsOnboarding,
  showMainContent,
  error,
}

/// State notifier for managing community screen state
class CommunityScreenStateNotifier extends StateNotifier<CommunityScreenState> {
  final CommunityService _communityService;
  final Ref _ref;

  CommunityScreenStateNotifier(this._communityService, this._ref)
      : super(CommunityScreenState.loading) {
    _checkCommunityState();

    // Listen to changes in community profile
    _ref.listen<AsyncValue<CommunityProfileEntity?>>(
      currentCommunityProfileProvider,
      (previous, next) {
        next.when(
          data: (profile) {
            if (profile != null && !profile.isDeleted) {
              // User has an ACTIVE profile, show main content
              if (state != CommunityScreenState.showMainContent) {
                Future.microtask(() {
                  state = CommunityScreenState.showMainContent;
                });
              }
            } else {
              // User doesn't have an active profile, show onboarding
              if (state != CommunityScreenState.needsOnboarding) {
                Future.microtask(() {
                  state = CommunityScreenState.needsOnboarding;
                });
              }
            }
          },
          loading: () {
            // Keep current state during loading unless we're in error state
            if (state == CommunityScreenState.error) {
              Future.microtask(() {
                state = CommunityScreenState.loading;
              });
            }
          },
          error: (error, stackTrace) {
            // On error, re-check the actual state instead of defaulting to onboarding
            Future.microtask(() => _checkCommunityState());
          },
        );
      },
    );
  }

  /// Check if user has community profile and set appropriate state
  Future<void> _checkCommunityState() async {
    try {
      Future.microtask(() {
        state = CommunityScreenState.loading;
      });

      // Check if user has an ACTIVE (non-deleted) community profile
      final hasActiveProfile = await _communityService.hasProfile();

      if (hasActiveProfile) {
        // Add small delay for newly created profiles to allow system sync
        try {
          final currentProfile =
              _ref.read(currentCommunityProfileProvider).valueOrNull;
          if (currentProfile != null) {
            final profileAge =
                DateTime.now().difference(currentProfile.createdAt);
            if (profileAge.inSeconds < 5) {
              await Future.delayed(Duration(seconds: 1));
            }
          }
        } catch (e) {
          // Could not check profile age, proceeding normally
        }

        Future.microtask(() {
          state = CommunityScreenState.showMainContent;
        });
      } else {
        Future.microtask(() {
          state = CommunityScreenState.needsOnboarding;
        });
      }
    } catch (e) {
      // On error, default to onboarding to be safe
      Future.microtask(() {
        state = CommunityScreenState.needsOnboarding;
      });
    }
  }

  /// Force refresh the community state
  void refresh() {
    _checkCommunityState();
  }

  /// Called when user completes onboarding to switch to main content
  void onboardingCompleted() {
    Future.microtask(() {
      state = CommunityScreenState.showMainContent;
    });
  }
}

/// Provider for community screen state notifier
final communityScreenStateProvider =
    StateNotifierProvider<CommunityScreenStateNotifier, CommunityScreenState>(
        (ref) {
  final service = ref.watch(communityServiceProvider);
  return CommunityScreenStateNotifier(service, ref);
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
    bool? isPlusUser,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.createProfile(
        displayName: displayName,
        gender: gender,
        isAnonymous: isAnonymous,
        avatarUrl: avatarUrl,
        isPlusUser: isPlusUser,
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
