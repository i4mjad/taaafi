import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/messaging/repositories/fcm_repository.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/notifications/data/models/app_notification.dart';
import 'package:reboot_app_3/features/notifications/data/repositories/notifications_repository.dart';
import 'package:reboot_app_3/features/notifications/data/database/notifications_database.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

part 'fcm_service.g.dart';

class MessagingService with WidgetsBindingObserver {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final FirebaseMessagingRepository _fcmRepository =
      FirebaseMessagingRepository(
    FirebaseMessaging.instance,
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
  final _localNotificationPlugin = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isFlutterNotificationPluginInitalized = false;

  // Global provider container for accessing repositories
  static ProviderContainer? _globalContainer;

  // Method to set the global container reference
  static void setGlobalContainer(ProviderContainer container) {
    _globalContainer = container;
  }

  // Pending message to handle once context is available
  RemoteMessage? _queuedMessage;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Add lifecycle observer to listen for app state changes
    WidgetsBinding.instance.addObserver(this);

    try {
      //1. Request permission
      await requestPermission();
    } catch (e) {
      // Continue with initialization even if permissions fail
    }

    try {
      //2. Setup message handler
      await _setupMessageHandler();
    } catch (e) {
      // Continue with initialization
    }

    try {
      //3. Get FCM token
      await getFCMToken();
    } catch (e) {
      // Continue with initialization
    }

    try {
      //4. Update FCM token
      await updateFCMToken();
    } catch (e) {
      // Continue with initialization
    }

    //5. Setup auth state listener for topic subscription
    _setupAuthStateListener();

    //6. Check if app was opened from a notification when terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Defer navigation until after the UI (and GoRouter) have been
      // completely built. We'll process this message later from MyApp.
      _queuedMessage = initialMessage;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
      provisional: false,
      carPlay: false,
      criticalAlert: false,
      announcement: false,
    );

    // Retrieve APNs token for iOS
    if (settings.authorizationStatus == AuthorizationStatus.authorized &&
        Platform.isIOS) {
      await _messaging.getAPNSToken();
    }
  }

  Future<void> setupFlutterNotification(RemoteMessage message) async {
    if (_isFlutterNotificationPluginInitalized) {
      return;
    }

    //Android Setup
    final channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    await _localNotificationPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initalAndroidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    //IOS Setup

    const initalIOSSettings = DarwinInitializationSettings();

    final initalSettings = InitializationSettings(
      android: initalAndroidSettings,
      iOS: initalIOSSettings,
    );

    await _localNotificationPlugin.initialize(initalSettings,
        onDidReceiveNotificationResponse: (response) async {
      // Handle navigation from local notification tap
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          // Parse payload back to Map if it contains navigation data
          // Note: You might need to encode/decode the payload properly
        } catch (e) {
          // Silent error - don't clutter logs
        }
      }
    });

    _isFlutterNotificationPluginInitalized = true;
  }

  Future<void> updateFCMToken() async {
    try {
      return await _fcmRepository.updateUserMessagingToken();
    } catch (e) {
      return null;
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _fcmRepository.getMessagingToken();
    } catch (e) {
      return null;
    }
  }

  Future<void> storeNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final notification = message.notification;

      // Store all notifications (not just report-related ones)
      if (notification != null) {
        final appNotification = AppNotification(
          id: message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: notification.title ?? 'New Notification',
          message: notification.body ?? 'You have a new notification',
          timestamp: message.sentTime ?? DateTime.now(),
          isRead: false,
          reportId: data['reportId'] ?? '',
          reportStatus: data['reportStatus'] ?? 'general',
          additionalData: data,
        );

        // Try to use repository first for proper state management
        if (_globalContainer != null) {
          try {
            await _globalContainer!
                .read(notificationsRepositoryProvider.notifier)
                .addNotification(appNotification);
          } catch (e) {
            await NotificationsDatabase.instance.create(appNotification);
          }
        } else {
          // Fallback to direct database access
          await NotificationsDatabase.instance.create(appNotification);
        }
      }
    } catch (e) {
      // Silent error - don't clutter logs
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      try {
        await _localNotificationPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'This channel is used for important notifications',
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      } catch (e) {
        // Silent error - don't clutter logs
      }
    }
  }

  Future<void> _setupMessageHandler() async {
    //Foreground
    FirebaseMessaging.onMessage.listen((message) async {
      print(
          '🔔 [FCM] Received foreground message: ${message.notification?.title}');

      await storeNotification(message);
      await setupFlutterNotification(message);
      await _showNotificationSnackbar(message);
      await showNotification(message);

      // Optionally navigate in foreground based on notification type
      final shouldNavigateInForeground =
          message.data['navigateInForeground'] == 'true';
      if (shouldNavigateInForeground) {
        await _handleNotificationNavigation(message);
      }
    });

    //Background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    //Opened app (cold start). We just queue the message and let the app
    //process it once navigation is fully ready.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _queuedMessage = initialMessage;
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Store notification in database
    await storeNotification(message);

    // Handle navigation based on notification data
    await _handleNotificationNavigation(message);

    await showNotification(message);
  }

  /// Shows a snackbar with notification content and navigation button
  Future<void> _showNotificationSnackbar(RemoteMessage message) async {
    final ctx = rootNavigatorKey.currentContext;

    if (ctx == null) {
      return;
    }

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    final localization = AppLocalizations.of(ctx);
    final title = notification.title ??
        localization.translate('notification-snackbar-new-title');
    final body = notification.body ??
        localization.translate('notification-snackbar-new-body');

    try {
      // Find the ScaffoldMessenger
      final scaffoldMessenger = ScaffoldMessenger.of(ctx);

      // Clear any existing snackbars
      scaffoldMessenger.clearSnackBars();

      // Show the snackbar using app's design system
      final theme = AppTheme.of(ctx);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 15,
              cornerSmoothing: 1,
            ),
            side: BorderSide(
              width: 2,
              color: theme.primary[300]!,
            ),
          ),
          backgroundColor: theme.primary[50],
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Icon(
                LucideIcons.bell,
                color: theme.primary[600]!,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  scaffoldMessenger.hideCurrentSnackBar();
                  // Navigate to notifications screen
                  try {
                    GoRouter.of(ctx).goNamed(RouteNames.notifications.name);
                  } catch (e) {
                    // Silent error - don't clutter logs
                  }
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: theme.primary[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localization.translate('notification-snackbar-view'),
                  style: TextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Silent error - don't clutter logs
    }
  }

  /// Handles navigation based on notification data
  Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    // Try to obtain a BuildContext from the rootNavigatorKey
    final ctx = rootNavigatorKey.currentContext;

    if (ctx == null) {
      // Context isn't ready yet – queue the message for later and retry
      _queuedMessage = message;
      // Retry after next frame (max 5 attempts to avoid infinite loop)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_queuedMessage != null) {
          _handleNotificationNavigation(_queuedMessage!);
        }
      });
      return;
    }

    // We have a context, clear any queued message
    _queuedMessage = null;

    final data = message.data;
    final screen = data['screen'];

    if (screen == null) {
      return;
    }

    // Add delay to ensure app is ready for navigation
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Comment out dynamic redirection - always redirect to notifications screen
      /*
      switch (screen) {
        case 'reportConversation':
        case 'reportDetails':
          final reportId = data['reportId'];
          if (reportId != null) {
            GoRouter.of(ctx).goNamed(
              RouteNames.reportConversation.name,
              pathParameters: {'reportId': reportId},
            );
          }
          break;

        case 'userReports':
          GoRouter.of(ctx).goNamed(RouteNames.userReports.name);
          break;

        case 'activities':
          GoRouter.of(ctx).goNamed(RouteNames.activities.name);
          break;

        case 'library':
          GoRouter.of(ctx).goNamed(RouteNames.library.name);
          break;

        case 'diaries':
          GoRouter.of(ctx).goNamed(RouteNames.diaries.name);
          break;

        case 'community':
          GoRouter.of(ctx).goNamed(RouteNames.community.name);
          break;

        case 'account':
          GoRouter.of(ctx).goNamed(RouteNames.account.name);
          break;

        case 'vault':
          GoRouter.of(ctx).goNamed(RouteNames.vault.name);
          break;

        case 'home':
        default:
          GoRouter.of(ctx).goNamed(RouteNames.home.name);
          break;
      }
      */

      // Always redirect to notifications screen
      GoRouter.of(ctx).goNamed(RouteNames.notifications.name);
    } catch (e) {
      // Silent error - don't clutter logs
    }
  }

  /// Sets up listener for authentication state changes
  /// Subscribes logged-in users to all_users topic
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User is signed in - subscribe to all_users topic and update FCM token
        await _subscribeToAllUsersGroup();
        await updateFCMToken();
      }
    });
  }

  /// Subscribes the logged-in user to the "all_users" messaging group
  Future<void> _subscribeToAllUsersGroup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Subscribe to FCM topic first (critical)
      await _messaging.subscribeToTopic('all_users');

      // Track subscription in Firestore (optional, non-blocking)
      _trackAllUsersSubscription(user.uid).catchError((e) {
        // Don't rethrow - this is optional
      });
    } catch (e) {
      // Silent error - don't clutter logs
    }
  }

  /// Tracks that the user is subscribed to the all_users group
  Future<void> _trackAllUsersSubscription(String userId) async {
    try {
      final userMembershipsRef =
          _firestore.collection('userGroupMemberships').doc(userId);

      final doc = await userMembershipsRef.get();
      List<Map<String, dynamic>> currentGroups = [];

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['groups'] != null) {
          currentGroups = List<Map<String, dynamic>>.from(data['groups']);
        }
      }

      // Check if already subscribed to all_users
      bool alreadySubscribed = currentGroups.any(
        (group) => group['topicId'] == 'all_users',
      );

      if (!alreadySubscribed) {
        final now = Timestamp.now();
        // Add all_users subscription
        currentGroups.add({
          'groupName': 'All Users',
          'groupNameAr': 'جميع المستخدمين',
          'topicId': 'all_users',
          'subscribedAt': now,
        });

        // Update user's memberships
        await userMembershipsRef.set({
          'userId': userId,
          'groups': currentGroups,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silent error - don't clutter logs
    }
  }

  /// Call this **after** the UI & GoRouter are ready (e.g. from MyApp) to
  /// process any message that was received while the app was terminated.
  void processQueuedMessage() {
    if (_queuedMessage != null) {
      final msg = _queuedMessage!;
      // Do NOT clear _queuedMessage yet. Let _handleNotificationNavigation
      // clear it when navigation actually succeeds (ctx available).
      _handleNotificationNavigation(msg);
    }
  }
}

@Riverpod(keepAlive: true)
FlutterLocalNotificationsPlugin localNotificationPlugin(Ref ref) {
  return FlutterLocalNotificationsPlugin();
}

@Riverpod(keepAlive: true)
FirebaseMessaging messaging(Ref ref) {
  return FirebaseMessaging.instance;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await MessagingService.instance.setupFlutterNotification(message);
  await MessagingService.instance.storeNotification(message);
  await MessagingService.instance.showNotification(message);
}
