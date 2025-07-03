import 'package:reboot_app_3/core/services/device_tracking_service.dart';

/// Example usage of DeviceTrackingService
class DeviceTrackingExample {
  static final DeviceTrackingService _deviceService =
      DeviceTrackingService.instance;

  /// Example: Get current device ID
  static Future<void> exampleGetDeviceId() async {
    try {
      final deviceId = await _deviceService.getDeviceId();
      print('Current device ID: $deviceId');
    } catch (e) {
      print('Error getting device ID: $e');
    }
  }

  /// Example: Update device IDs for current user
  static Future<void> exampleUpdateCurrentUserDevices() async {
    try {
      final currentUserDeviceIds =
          await _deviceService.getCurrentUserDeviceIds();
      print('Device IDs updated successfully');
      print('Current user has ${currentUserDeviceIds.length} devices');
    } catch (e) {
      print('Error updating device IDs: $e');
    }
  }

  /// Example: Get all device IDs for current user
  static Future<void> exampleGetCurrentUserDevices() async {
    try {
      final deviceIds = await _deviceService.getCurrentUserDeviceIds();
      print('Current user device IDs: $deviceIds');
      print('Device count: ${deviceIds.length}');
    } catch (e) {
      print('Error getting user device IDs: $e');
    }
  }

  /// Example: Get device info for debugging
  static Future<void> exampleGetDeviceInfo() async {
    try {
      final info = await _deviceService.getDeviceInfo();
      print('=== Device Information ===');
      print('Current Device ID: ${info['currentDeviceId']}');
      print('User ID: ${info['userId']}');
      print('Device Count: ${info['deviceCount']}');
      print('User Device IDs: ${info['userDeviceIds']}');

      if (info['deviceDetails'] != null) {
        final details = info['deviceDetails'] as Map<String, dynamic>;
        print('Platform: ${details['platform']}');

        if (details['platform'] == 'Android') {
          print('Android ID: ${details['androidId']}');
          print('Brand: ${details['brand']}');
          print('Model: ${details['model']}');
          print('Manufacturer: ${details['manufacturer']}');
          print('SDK Version: ${details['sdkInt']}');
          print('Android Version: ${details['release']}');
        } else if (details['platform'] == 'iOS') {
          print('Device Name: ${details['name']}');
          print('Model: ${details['model']}');
          print('iOS Version: ${details['systemVersion']}');
          print('Identifier for Vendor: ${details['identifierForVendor']}');
          print('Is Physical Device: ${details['isPhysicalDevice']}');
        }
      }
      print('========================');
    } catch (e) {
      print('Error getting device info: $e');
    }
  }

  /// Example: Update device IDs for specific user (admin use)
  static Future<void> exampleUpdateSpecificUserDevices(String userId) async {
    try {
      await _deviceService.updateUserDeviceIds(userId);
      print('Device IDs updated for user: $userId');
    } catch (e) {
      print('Error updating device IDs for user $userId: $e');
    }
  }

  /// Example: Remove device ID from user
  static Future<void> exampleRemoveDeviceFromUser(
      String userId, String deviceId) async {
    try {
      await _deviceService.removeDeviceIdFromUser(userId, deviceId);
      print('Device ID $deviceId removed from user $userId');
    } catch (e) {
      print('Error removing device ID: $e');
    }
  }

  /// Complete example workflow
  static Future<void> exampleCompleteWorkflow() async {
    print('=== Device Tracking Service Example ===');

    // 1. Get current device ID
    await exampleGetDeviceId();

    // 2. Update current user's device list
    await exampleUpdateCurrentUserDevices();

    // 3. Get all device IDs for current user
    await exampleGetCurrentUserDevices();

    // 4. Get detailed device info
    await exampleGetDeviceInfo();

    print('=== Example completed ===');
  }
}
