import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/services/revenue_cat_service.dart';

part 'revenue_cat_auth_sync_service.g.dart';

/// Service that syncs Firebase authentication state with RevenueCat user identity
/// Ensures purchases are properly attributed to the correct Firebase user
class RevenueCatAuthSyncService {
  final RevenueCatService _revenueCatService;
  StreamSubscription<User?>? _authSubscription;
  String? _lastSyncedUserId;

  RevenueCatAuthSyncService(this._revenueCatService);

  /// Initialize the service and start listening to auth state changes
  Future<void> initialize() async {
    try {
      // Initialize RevenueCat with current user (if any)
      final currentUser = FirebaseAuth.instance.currentUser;
      await _revenueCatService.initialize(userId: currentUser?.uid);
      _lastSyncedUserId = currentUser?.uid;

      // Start listening to auth state changes
      _startAuthStateListener();

      print(
          'RevenueCat Auth Sync: Successfully initialized and listening to auth changes');
    } on RevenueCatNotAvailableException catch (e) {
      print('RevenueCat Auth Sync: Plugin not available - $e');
      print(
          'RevenueCat Auth Sync: Subscription features will be disabled until plugin is properly installed');
      // Don't start auth listener if RevenueCat isn't available
    } catch (e) {
      print('RevenueCat Auth Sync: Initialization failed - $e');
      // Still start auth listener for when RevenueCat becomes available
      _startAuthStateListener();
    }
  }

  /// Start listening to Firebase auth state changes
  void _startAuthStateListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) async {
        await _handleAuthStateChange(user);
      },
      onError: (error) {
        print('RevenueCat Auth Sync Error: $error');
      },
    );
  }

  /// Handle authentication state changes
  Future<void> _handleAuthStateChange(User? user) async {
    try {
      final newUserId = user?.uid;

      // Skip if the user hasn't actually changed
      if (_lastSyncedUserId == newUserId) {
        // Only log occasionally to avoid spam
        if (_shouldLogUserUnchanged()) {
          print('RevenueCat Auth Sync: User unchanged, skipping sync');
        }
        return;
      }

      if (user != null) {
        // User logged in: Update RevenueCat with Firebase UID
        await _revenueCatService.login(user.uid);
        print('RevenueCat: Synced with Firebase user ${user.uid}');
        _lastSyncedUserId = user.uid;
      } else {
        // User logged out: Switch RevenueCat to anonymous mode
        await _revenueCatService.logout();
        print('RevenueCat: Switched to anonymous mode');
        _lastSyncedUserId = null;
      }
    } catch (e) {
      print('RevenueCat Auth Sync failed: $e');
      // Don't throw - auth sync failure shouldn't break the app
    }
  }

  static DateTime? _lastUserUnchangedLog;
  static const Duration _logThrottleDuration = Duration(minutes: 1);

  /// Check if we should log "user unchanged" message (throttled to avoid spam)
  bool _shouldLogUserUnchanged() {
    final now = DateTime.now();
    if (_lastUserUnchangedLog == null ||
        now.difference(_lastUserUnchangedLog!) > _logThrottleDuration) {
      _lastUserUnchangedLog = now;
      return true;
    }
    return false;
  }

  /// Manually sync a specific user ID with RevenueCat
  /// Useful for testing or manual user switches
  Future<void> syncUser(String? userId) async {
    try {
      if (userId != null) {
        await _revenueCatService.login(userId);
        _lastSyncedUserId = userId;
      } else {
        await _revenueCatService.logout();
        _lastSyncedUserId = null;
      }
    } catch (e) {
      print('Manual RevenueCat user sync failed: $e');
      rethrow;
    }
  }

  /// Force sync current Firebase user with RevenueCat
  /// Useful when we need to ensure user is properly synced before operations
  Future<void> forceSyncCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    print(
        'RevenueCat Auth Sync: Force syncing current user ${currentUser?.uid}');

    if (currentUser?.uid != null) {
      await _revenueCatService.login(currentUser!.uid);
      _lastSyncedUserId = currentUser.uid;
      print(
          'RevenueCat Auth Sync: Force sync completed for user ${currentUser.uid}');
    } else {
      await _revenueCatService.logout();
      _lastSyncedUserId = null;
      print('RevenueCat Auth Sync: Force sync completed - anonymous mode');
    }
  }

  /// Check if sync is potentially needed without triggering operations
  bool isSyncNeeded() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return _lastSyncedUserId != currentUser?.uid;
  }

  /// Get the current RevenueCat customer info
  /// This will include the properly attributed Firebase UID
  Future<String?> getCurrentRevenueCatUserId() async {
    try {
      final customerInfo = await _revenueCatService.getCustomerInfo();
      return customerInfo.originalAppUserId;
    } catch (e) {
      print('Failed to get RevenueCat user ID: $e');
      return null;
    }
  }

  /// Check if current Firebase user matches RevenueCat user
  Future<bool> isUserSynced() async {
    try {
      final currentFirebaseUser = FirebaseAuth.instance.currentUser;
      final revenueCatUserId = await getCurrentRevenueCatUserId();

      if (currentFirebaseUser?.uid == null &&
          revenueCatUserId?.startsWith('firebase:') == false) {
        // Both are anonymous/null - consider synced
        return true;
      }

      return currentFirebaseUser?.uid == revenueCatUserId;
    } catch (e) {
      print('Failed to check user sync status: $e');
      return false;
    }
  }

  /// Dispose the service and clean up listeners
  void dispose() {
    _authSubscription?.cancel();
  }
}

@riverpod
RevenueCatAuthSyncService revenueCatAuthSyncService(Ref ref) {
  final service = RevenueCatAuthSyncService(
    ref.read(revenueCatServiceProvider),
  );

  // Clean up the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider that initializes the RevenueCat auth sync service
@riverpod
Future<void> initializeRevenueCatAuthSync(Ref ref) async {
  final syncService = ref.read(revenueCatAuthSyncServiceProvider);
  await syncService.initialize();
}
