import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/community/data/models/notification_preferences.dart';
import 'package:reboot_app_3/features/community/domain/services/community_service.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    communityService: ref.read(communityServiceProvider),
    localNotifications: FlutterLocalNotificationsPlugin(),
  );
});

/// Service for handling notification permissions and preferences
class NotificationService {
  final CommunityService _communityService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService({
    required CommunityService communityService,
    required FlutterLocalNotificationsPlugin localNotifications,
  })  : _communityService = communityService,
        _localNotifications = localNotifications;

  /// Check if system-level notifications are enabled for the app
  Future<bool> areSystemNotificationsEnabled() async {
    try {
      // Check Firebase messaging permissions
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final isFirebaseEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      // Check local notifications permissions (Android)
      final bool? localEnabled = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();

      // Return true if either method indicates notifications are enabled
      return isFirebaseEnabled || (localEnabled ?? false);
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      // Request Firebase messaging permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final isFirebaseEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      // Request local notification permissions for iOS
      final bool? iosResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Request local notification permissions for Android 13+
      final bool? androidResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      return isFirebaseEnabled ||
          (iosResult ?? false) ||
          (androidResult ?? false);
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Get current notification preferences with system check
  Future<NotificationPreferences> getCurrentNotificationPreferences() async {
    try {
      final profile = await _communityService.getCurrentProfile();

      // Get system notification status
      final systemEnabled = await areSystemNotificationsEnabled();

      if (profile?.notificationPreferences != null) {
        // Update with current system status
        return profile!.notificationPreferences!.copyWith(
          appNotificationsEnabled: systemEnabled,
        );
      } else {
        // Return defaults with current system status
        return NotificationPreferences.defaultPreferences.copyWith(
          appNotificationsEnabled: systemEnabled,
        );
      }
    } catch (e) {
      print('Error getting notification preferences: $e');
      // Return defaults with system check
      final systemEnabled = await areSystemNotificationsEnabled();
      return NotificationPreferences.defaultPreferences.copyWith(
        appNotificationsEnabled: systemEnabled,
      );
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
      NotificationPreferences preferences) async {
    try {
      // Get current system status
      final systemEnabled = await areSystemNotificationsEnabled();

      // Update preferences with current system status
      final updatedPreferences = preferences.copyWith(
        appNotificationsEnabled: systemEnabled,
      );

      // Update the community profile with the new preferences
      await _communityService.updateProfile(
        notificationPreferences: updatedPreferences,
      );
    } catch (e) {
      print('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Check system notification status and update preferences accordingly
  /// If system notifications are disabled, all notification preferences are set to false
  Future<NotificationPreferences> checkAndUpdateSystemStatus() async {
    try {
      final systemEnabled = await areSystemNotificationsEnabled();
      final currentPreferences = await getCurrentNotificationPreferences();

      // If system notifications are disabled, disable all preferences
      if (!systemEnabled) {
        final disabledPreferences = NotificationPreferences(
          appNotificationsEnabled: false,
          messagesNotifications: false,
          challengesNotifications: false,
          updateNotifications: false,
        );

        // Only update if preferences have actually changed
        if (currentPreferences != disabledPreferences) {
          await _communityService.updateProfile(
            notificationPreferences: disabledPreferences,
          );
        }

        return disabledPreferences;
      } else {
        // System is enabled, just update the system status
        final updatedPreferences = currentPreferences.copyWith(
          appNotificationsEnabled: true,
        );

        // Only update if system status has changed
        if (currentPreferences.appNotificationsEnabled != true) {
          await _communityService.updateProfile(
            notificationPreferences: updatedPreferences,
          );
        }

        return updatedPreferences;
      }
    } catch (e) {
      print('Error checking system notification status: $e');
      // Return current preferences if there's an error
      return await getCurrentNotificationPreferences();
    }
  }

  /// Initialize notification preferences for new group members
  Future<void> initializeNotificationPreferences() async {
    try {
      final currentProfile = await _communityService.getCurrentProfile();

      // Only initialize if preferences don't exist
      if (currentProfile?.notificationPreferences == null) {
        final systemEnabled = await areSystemNotificationsEnabled();
        final defaultPreferences =
            NotificationPreferences.defaultPreferences.copyWith(
          appNotificationsEnabled: systemEnabled,
        );

        await _communityService.updateProfile(
          notificationPreferences: defaultPreferences,
        );
      }
    } catch (e) {
      print('Error initializing notification preferences: $e');
      rethrow;
    }
  }
}
