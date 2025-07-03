import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/services/device_tracking_service.dart';

class DeviceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceTrackingService _trackingService = DeviceTrackingService.instance;

  /// Generate and store device ID
  Future<String> getDeviceId() async {
    return await _trackingService.getDeviceId();
  }

  /// Store device ID in user profile (updated to prevent duplicates)
  Future<void> registerDeviceForUser(String userId, String deviceId) async {
    try {
      // Use the new tracking service which prevents duplicates
      await _trackingService.updateUserDeviceIds(userId);
    } catch (e) {
      print('Error registering device: $e');
      rethrow;
    }
  }

  /// Get all device IDs for current user
  Future<List<String>> getCurrentUserDeviceIds() async {
    return await _trackingService.getCurrentUserDeviceIds();
  }

  /// Get device IDs for a specific user (admin use)
  Future<List<String>> getUserDeviceIds(String userId) async {
    return await _trackingService.getUserDeviceIds(userId);
  }

  /// Remove device ID from user profile (on logout/uninstall)
  Future<void> unregisterDeviceForUser(String userId, String deviceId) async {
    return await _trackingService.removeDeviceIdFromUser(userId, deviceId);
  }

  /// Initialize device tracking for current session
  Future<void> initializeDeviceTracking() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _trackingService.updateUserDeviceIds(user.uid);
    }
  }

  /// Update device IDs list for current user (no duplicates)
  Future<void> updateCurrentUserDeviceIds() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _trackingService.updateUserDeviceIds(user.uid);
    }
  }

  /// Get device tracking information for debugging
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return await _trackingService.getDeviceInfo();
  }
}
