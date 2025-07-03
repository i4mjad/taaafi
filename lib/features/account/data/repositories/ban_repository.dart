import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import '../models/ban.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ban_repository.g.dart';

/// Repository responsible for ban-related Firestore operations
class BanRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref ref;

  BanRepository(this._firestore, this._auth, this.ref);

  String? _getUserId() => _auth.currentUser?.uid;

  /// Get all active bans for a specific user
  Future<List<Ban>> getUserBans(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => ban.isCurrentlyActive)
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get active bans for the current user
  Future<List<Ban>> getCurrentUserBans() async {
    try {
      final userId = _getUserId();
      if (userId == null) return [];
      return await getUserBans(userId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get a specific feature ban for a user
  Future<Ban?> getUserFeatureBan(
      String userId, String featureUniqueName) async {
    try {
      final bans = await getUserBans(userId);

      // Check for app-wide bans first
      final appWideBan =
          bans.where((ban) => ban.scope == BanScope.app_wide).firstOrNull;
      if (appWideBan != null) return appWideBan;

      // Then check for feature-specific bans
      return bans
          .where((ban) =>
              ban.scope == BanScope.feature_specific &&
              ban.restrictedFeatures != null &&
              ban.restrictedFeatures!.contains(featureUniqueName))
          .firstOrNull;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get bans by device IDs (for device tracking)
  Future<List<Ban>> getBansByDeviceIds(List<String> deviceIds) async {
    try {
      if (deviceIds.isEmpty) return [];

      // Limit to 10 device IDs for Firestore query limitations
      final limitedDeviceIds = deviceIds.take(10).toList();

      final querySnapshot = await _firestore
          .collection('bans')
          .where('deviceIds', arrayContainsAny: limitedDeviceIds)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => ban.isCurrentlyActive)
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Check if a user has app-wide bans
  Future<bool> hasAppWideBans(String userId) async {
    try {
      final bans = await getUserBans(userId);
      return bans.any((ban) => ban.scope == BanScope.app_wide);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false; // Fail safe
    }
  }

  /// Check if current user has app-wide bans
  Future<bool> currentUserHasAppWideBans() async {
    try {
      final userId = _getUserId();
      if (userId == null) return false;
      return await hasAppWideBans(userId);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false; // Fail safe
    }
  }

  /// Stream of user bans for real-time updates
  Stream<List<Ban>> watchUserBans(String userId) {
    return _firestore
        .collection('bans')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => ban.isCurrentlyActive)
          .toList();
    });
  }

  /// Stream of current user bans
  Stream<List<Ban>> watchCurrentUserBans() {
    final userId = _getUserId();
    if (userId == null) {
      return Stream.value([]);
    }
    return watchUserBans(userId);
  }

  /// Get device ban history for violations (admin panel)
  Future<List<Ban>> getDeviceBanHistory(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('userId', isEqualTo: userId)
          .orderBy('issuedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => Ban.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get all active bans for a specific device (global check)
  Future<List<Ban>> getDeviceBans(String deviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('type', isEqualTo: BanType.device_ban.name)
          .where('isActive', isEqualTo: true)
          .where('restrictedDevices', arrayContains: deviceId)
          .get();

      return querySnapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => ban.isCurrentlyActive)
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }
}

// ==================== PROVIDERS ====================

@riverpod
BanRepository banRepository(BanRepositoryRef ref) {
  return BanRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref,
  );
}
