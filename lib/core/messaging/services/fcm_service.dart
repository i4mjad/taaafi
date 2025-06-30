import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reboot_app_3/core/messaging/repositories/fcm_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_service.g.dart';

class MessagingService {
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

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    if (message.data["type"] == "news") {
      //Do something
    }
    await showNotification(message);
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
