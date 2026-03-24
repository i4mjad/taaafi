import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:reboot_app_3/core/services/persistent_device_id_service.dart';

/// Service for managing device tracking and updating user device IDs
/// Ensures no duplicate device IDs are stored in user documents
class DeviceTrackingService {
  DeviceTrackingService._();

  static final DeviceTrackingService instance = DeviceTrackingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize device tracking service
  Future<void> init() async {
    try {
      // Handle first-run cleanup (iOS Keychain management)
      await PersistentDeviceIdService.instance.handleFirstRunCleanup();

      // Migrate old device ID if needed (register both old and new IDs)
      await _migrateDeviceId();

      // Set up auth state listener
      _setupAuthStateListener();

      // Update device tracking for current user if logged in
      final user = _auth.currentUser;
      if (user != null) {
        await updateUserDeviceIds(user.uid);
      }
    } catch (e) {}
  }

  /// Migrate from old IDFV/SharedPreferences device ID to persistent ID.
  /// Registers both old and new IDs in Firestore so existing bans still match.
  Future<void> _migrateDeviceId() async {
    try {
      final persistentService = PersistentDeviceIdService.instance;
      if (await persistentService.isMigrated()) return;

      final oldDeviceId = await persistentService.getOldDeviceId();
      final newDeviceId = await persistentService.getDeviceId();

      if (oldDeviceId != null && oldDeviceId != newDeviceId) {
        // Register both device IDs for the current user
        final user = _auth.currentUser;
        if (user != null) {
          final userRef = _firestore.collection('users').doc(user.uid);
          await userRef.update({
            'devicesIds': FieldValue.arrayUnion([oldDeviceId, newDeviceId]),
            'lastDeviceUpdate': FieldValue.serverTimestamp(),
          });
        }
      }

      await persistentService.markMigrated();
    } catch (_) {}
  }

  /// Get persistent device ID (survives app reinstall)
  Future<String> getDeviceId() async {
    return await PersistentDeviceIdService.instance.getDeviceId();
  }

  /// Update device IDs list for user (no duplicates)
  Future<void> updateUserDeviceIds(String userId) async {
    try {
      final deviceId = await getDeviceId();

      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await userRef.set({
          'devicesIds': [deviceId],
          'lastDeviceUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return;
      }

      final userData = userDoc.data()!;
      final currentDeviceIds = List<String>.from(userData['devicesIds'] ?? []);

      // Only update if device ID is not already in the list
      if (!currentDeviceIds.contains(deviceId)) {
        // Add new device ID using arrayUnion to avoid duplicates
        await userRef.update({
          'devicesIds': FieldValue.arrayUnion([deviceId]),
          'lastDeviceUpdate': FieldValue.serverTimestamp(),
        });

        // Clean up old device IDs if we have too many
        final updatedDeviceIds = [...currentDeviceIds, deviceId];
        if (updatedDeviceIds.length > 10) {
          final deviceIdsToKeep =
              updatedDeviceIds.sublist(updatedDeviceIds.length - 10);
          await userRef.update({
            'devicesIds': deviceIdsToKeep,
            'lastDeviceUpdate': FieldValue.serverTimestamp(),
          });
        }
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's device IDs
  Future<List<String>> getCurrentUserDeviceIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await getUserDeviceIds(user.uid);
    } catch (e) {
      return [];
    }
  }

  /// Get device IDs for a specific user
  Future<List<String>> getUserDeviceIds(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data != null && data['devicesIds'] != null) {
        return List<String>.from(data['devicesIds']);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Remove device ID from user profile
  Future<void> removeDeviceIdFromUser(String userId, String deviceId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'devicesIds': FieldValue.arrayRemove([deviceId]),
        'lastDeviceUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Set up auth state listener
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User signed in - update device tracking
        await updateUserDeviceIds(user.uid);
      }
    });
  }

  /// Get device info for debugging
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      final user = _auth.currentUser;
      final userDeviceIds =
          user != null ? await getUserDeviceIds(user.uid) : <String>[];

      // Get detailed device information
      final deviceDetails = await _getDetailedDeviceInfo();

      return {
        'currentDeviceId': deviceId,
        'userId': user?.uid,
        'userDeviceIds': userDeviceIds,
        'deviceCount': userDeviceIds.length,
        'deviceDetails': deviceDetails,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get detailed device information for debugging
  Future<Map<String, dynamic>> _getDetailedDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'id': androidInfo.id,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidId': androidInfo.id,
          'sdkInt': androidInfo.version.sdkInt,
          'release': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else {
        return {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      return {
        'platform': Platform.operatingSystem,
        'error': e.toString(),
      };
    }
  }
}
