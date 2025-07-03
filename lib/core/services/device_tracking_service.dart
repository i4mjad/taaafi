import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for managing device tracking and updating user device IDs
/// Ensures no duplicate device IDs are stored in user documents
class DeviceTrackingService {
  DeviceTrackingService._();

  static final DeviceTrackingService instance = DeviceTrackingService._();

  static const String _deviceIdKey = 'device_id';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize device tracking service
  Future<void> init() async {
    try {
      // Set up auth state listener
      _setupAuthStateListener();

      // Update device tracking for current user if logged in
      final user = _auth.currentUser;
      if (user != null) {
        await updateUserDeviceIds(user.uid);
      }
    } catch (e) {
      print('Error initializing device tracking service: $e');
    }
  }

  /// Generate and get device ID
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Generate unique device ID using device_info_plus
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use Android ID as the primary identifier
        return 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Use identifierForVendor as the primary identifier
        return 'ios_${iosInfo.identifierForVendor ?? 'unknown'}';
      } else {
        // Fallback for other platforms
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return 'device_${Platform.operatingSystem}_$timestamp';
      }
    } catch (e) {
      print('Error getting device info: $e');
      // Fallback to timestamp-based ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'device_fallback_$timestamp';
    }
  }

  /// Update device IDs list for user (no duplicates)
  Future<void> updateUserDeviceIds(String userId) async {
    try {
      final deviceId = await getDeviceId();
      print('Updating device ID: $deviceId for user: $userId');

      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await userRef.set({
          'devicesIds': [deviceId],
          'lastDeviceUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Created new user document with device ID');
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
        print('Added device ID to existing user document');

        // Clean up old device IDs if we have too many
        final updatedDeviceIds = [...currentDeviceIds, deviceId];
        if (updatedDeviceIds.length > 10) {
          final deviceIdsToKeep =
              updatedDeviceIds.sublist(updatedDeviceIds.length - 10);
          await userRef.update({
            'devicesIds': deviceIdsToKeep,
            'lastDeviceUpdate': FieldValue.serverTimestamp(),
          });
          print('Cleaned up old device IDs, keeping last 10');
        }
      } else {
        print('Device ID already exists for user');
      }
    } catch (e) {
      print('Error updating user device IDs: $e');
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
      print('Error getting current user device IDs: $e');
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
      print('Error getting device IDs for user $userId: $e');
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
      print('Error removing device ID from user: $e');
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
