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
  bool _isFlutterNotificationPluginInitalized = false;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    //1. Request permission
    await requestPermission();

    //2. Setup message handler
    await _setupMessageHandler();

    //3. Get FCM token
    await getFCMToken();

    //4. Update FCM token
    await updateFCMToken();
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
    } else {
      print(
          "Notification permissions not granted: ${settings.authorizationStatus}");
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

    //TODO: figure out how to change this to the actual app icon
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
