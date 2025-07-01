import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/messaging/repositories/fcm_repository.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      print('Error requesting permissions: $e');
      // Continue with initialization even if permissions fail
    }

    try {
      //2. Setup message handler
      await _setupMessageHandler();
    } catch (e) {
      print('Error setting up message handler: $e');
      // Continue with initialization
    }

    try {
      //3. Get FCM token
      await getFCMToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      // Continue with initialization
    }

    try {
      //4. Update FCM token
      await updateFCMToken();
    } catch (e) {
      print('Error updating FCM token: $e');
      // Continue with initialization
    }

    //5. Setup auth state listener for topic subscription
    _setupAuthStateListener();

    //6. Check if app was opened from a notification when terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.messageId}');
      // Use post frame callback to ensure navigation is ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _handleNotificationNavigation(initialMessage);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Clear badge when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      clearBadge();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Public method to get and print FCM token for testing
  static Future<String?> printFCMToken() async {
    try {
      final token = await instance._messaging.getToken();
      print('====================================');
      print('FCM TOKEN FOR TESTING:');
      print(token);
      print('====================================');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Clears the app badge count on iOS
  Future<void> clearBadge() async {
    if (Platform.isIOS) {
      try {
        // Set badge to 0 using a hidden notification
        await _localNotificationPlugin.show(
          99999, // Use a high ID to avoid conflicts
          '', // empty title
          '', // empty body
          NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentBadge: true,
              presentSound: false,
              badgeNumber: 0, // Set badge to 0
            ),
          ),
        );

        // Immediately cancel the hidden notification
        await _localNotificationPlugin.cancel(99999);

        print('Badge cleared successfully');
      } catch (e) {
        print('Error clearing badge: $e');
      }
    }
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

    final initalIOSSettings = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        print('onDidReceiveLocalNotification: $id, $title, $body, $payload');
      },
    );

    final initalSettings = InitializationSettings(
      android: initalAndroidSettings,
      iOS: initalIOSSettings,
    );

    await _localNotificationPlugin.initialize(initalSettings,
        onDidReceiveNotificationResponse: (response) async {
      print('onDidReceiveNotificationResponse: $response');
      // Clear badge when user taps on notification
      await clearBadge();

      // Handle navigation from local notification tap
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          // Parse payload back to Map if it contains navigation data
          // Note: You might need to encode/decode the payload properly
          print('Notification payload: ${response.payload}');
        } catch (e) {
          print('Error handling notification tap: $e');
        }
      }
    });

    _isFlutterNotificationPluginInitalized = true;
  }

  Future<void> updateFCMToken() async {
    try {
      return await _fcmRepository.updateUserMessagingToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _fcmRepository.getMessagingToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      _localNotificationPlugin.show(
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
    }
  }

  Future<void> _setupMessageHandler() async {
    //Foreground
    FirebaseMessaging.onMessage.listen((message) async {
      print('onMessage: $message');
      await showNotification(message);

      // Optionally navigate in foreground based on notification type
      // You can customize this behavior based on your requirements
      final shouldNavigateInForeground =
          message.data['navigateInForeground'] == 'true';
      if (shouldNavigateInForeground) {
        await _handleNotificationNavigation(message);
      }
    });

    //Background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    //Opened app
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleBackgroundMessage(initialMessage);
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');

    // Clear badge when app is opened from notification
    await clearBadge();

    // Handle navigation based on notification data
    await _handleNotificationNavigation(message);

    await showNotification(message);
  }

  /// Handles navigation based on notification data
  Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    // Try to obtain a BuildContext from the rootNavigatorKey
    final ctx = rootNavigatorKey.currentContext;

    if (ctx == null) {
      // Context isn't ready yet – queue the message for later and retry
      print('BuildContext not ready yet. Queuing navigation.');
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
      print('No screen specified in notification data');
      return;
    }

    print('Navigating to screen: $screen with data: $data');

    // Add delay to ensure app is ready for navigation
    await Future.delayed(const Duration(milliseconds: 100));

    try {
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
    } catch (e) {
      print('Error navigating from notification: $e');
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
      print('Successfully subscribed to all_users topic');

      // Track subscription in Firestore (optional, non-blocking)
      _trackAllUsersSubscription(user.uid).catchError((e) {
        print('Error tracking subscription in Firestore: $e');
        // Don't rethrow - this is optional
      });
    } catch (e) {
      print('Error subscribing to all_users topic: $e');
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
      print('Error tracking all_users subscription: $e');
    }
  }
}

@Riverpod(keepAlive: true)
FlutterLocalNotificationsPlugin localNotificationPlugin(
    LocalNotificationPluginRef ref) {
  return FlutterLocalNotificationsPlugin();
}

@Riverpod(keepAlive: true)
FirebaseMessaging messaging(MessagingRef ref) {
  return FirebaseMessaging.instance;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await MessagingService.instance.setupFlutterNotification(message);
  await MessagingService.instance.showNotification(message);
}
