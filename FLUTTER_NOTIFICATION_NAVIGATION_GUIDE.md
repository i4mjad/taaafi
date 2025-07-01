# Flutter App Notification Navigation Guide (GoRouter Edition)

This guide explains how to implement push notification handling with GoRouter navigation in your Flutter app, following the simplified approach from the Medium article.

## Overview

The admin panel sends push notifications with simple data fields. When a user taps on a notification, the app reads the `screen` field and navigates using GoRouter's `goNamed` method.

## Notification Payload Structure

All push notifications from the admin panel follow this simple structure:

```json
{
  "notification": {
    "title": "Report Update",
    "body": "Your report has been updated"
  },
  "data": {
    "screen": "reportDetails",
    "reportId": "abc123",
    "status": "inProgress",
    "type": "report_update",
    "locale": "en"
  }
}
```

### Key Fields

- **`data.screen`**: The GoRouter named route (e.g., 'reportDetails', 'home', 'profile')
- **`data.type`**: The notification type for analytics
- **Additional fields**: Any parameters needed by the target screen as simple key-value pairs

## Notification Types

Currently supported notification types:

| Type | Screen (GoRouter name) | Description | Parameters |
|------|------------------------|-------------|------------|
| `report_update` | `reportDetails` | Report status update | `reportId`, `status` |
| `new_message` | `reportDetails` | New message in report | `reportId`, `openConversation` |
| `announcement` | `announcements` | General announcement | `announcementId` |
| `group_update` | `groupDetails` | Group update | `groupId` |
| `content_update` | `contentDetails` | Content update | `contentId` |

## Flutter Implementation with GoRouter

### 1. Setup Firebase Messaging

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize(BuildContext context) async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get token for sending to backend
    String? token = await _fcm.getToken();
    print('FCM Token: $token');
    // TODO: Send token to your backend
    
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(context, message);
    });
    
    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Use a post-frame callback to ensure navigation is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(context, initialMessage);
      });
    }
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app notification (e.g., using a snackbar or overlay)
    print('Foreground message: ${message.notification?.title}');
    // You can show a dialog or snackbar here
  }
  
  void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    // Navigate based on the screen field
    final data = message.data;
    final screen = data['screen'];
    
    if (screen != null) {
      _navigateToScreen(context, screen, data);
    }
  }
  
  void _navigateToScreen(BuildContext context, String screen, Map<String, dynamic> data) {
    // Use GoRouter's goNamed for navigation
    switch (screen) {
      case 'reportDetails':
        context.goNamed(
          'reportDetails',
          pathParameters: {'reportId': data['reportId'] ?? ''},
          queryParameters: {
            'openConversation': data['openConversation'] ?? 'false',
          },
        );
        break;
      
      case 'announcements':
        context.goNamed(
          'announcements',
          queryParameters: {'id': data['announcementId'] ?? ''},
        );
        break;
      
      case 'groupDetails':
        context.goNamed(
          'groupDetails',
          pathParameters: {'groupId': data['groupId'] ?? ''},
        );
        break;
      
      case 'contentDetails':
        context.goNamed(
          'contentDetails',
          pathParameters: {'contentId': data['contentId'] ?? ''},
        );
        break;
      
      default:
        // Navigate to home or do nothing
        context.goNamed('home');
    }
  }
}
```

### 2. GoRouter Configuration

Set up your GoRouter with named routes:

```dart
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    
    GoRoute(
      name: 'reportDetails',
      path: '/reports/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        final openConversation = state.queryParameters['openConversation'] == 'true';
        
        return ReportDetailsScreen(
          reportId: reportId,
          openConversation: openConversation,
        );
      },
    ),
    
    GoRoute(
      name: 'announcements',
      path: '/announcements',
      builder: (context, state) {
        final announcementId = state.queryParameters['id'];
        return AnnouncementScreen(announcementId: announcementId);
      },
    ),
    
    GoRoute(
      name: 'groupDetails',
      path: '/groups/:groupId',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        return GroupDetailsScreen(groupId: groupId);
      },
    ),
    
    GoRoute(
      name: 'contentDetails',
      path: '/content/:contentId',
      builder: (context, state) {
        final contentId = state.pathParameters['contentId']!;
        return ContentDetailsScreen(contentId: contentId);
      },
    ),
  ],
);
```

### 3. Complete Integration Example

Here's a complete example integrating GoRouter with Firebase notifications:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
  // Note: Navigation is not possible here as there's no BuildContext
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final NotificationService _notificationService;
  
  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ta3afi',
      routerConfig: router,
      builder: (context, child) {
        // Initialize notifications with context
        _notificationService.initialize(context);
        return child!;
      },
    );
  }
}

// Alternative approach using a navigatorKey with GoRouter
class MyAppWithNavigatorKey extends StatefulWidget {
  @override
  _MyAppWithNavigatorKeyState createState() => _MyAppWithNavigatorKeyState();
}

class _MyAppWithNavigatorKeyState extends State<MyAppWithNavigatorKey> {
  late final GoRouter _router;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize router with navigatorKey
    _router = GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      routes: [
        // ... your routes here
      ],
    );
    
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    final fcm = FirebaseMessaging.instance;
    
    // Request permission
    await fcm.requestPermission();
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message.data);
    });
    
    // Check if app was opened from notification
    RemoteMessage? initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(initialMessage.data);
      });
    }
  }
  
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'];
    if (screen == null) return;
    
    // Navigate using GoRouter
    switch (screen) {
      case 'reportDetails':
        _router.goNamed(
          'reportDetails',
          pathParameters: {'reportId': data['reportId'] ?? ''},
          queryParameters: {
            if (data['openConversation'] == 'true') 'openConversation': 'true',
          },
        );
        break;
      // Add more cases as needed
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ta3afi',
      routerConfig: _router,
    );
  }
}
```

## Example Usage from Admin Panel

When the admin panel sends notifications for reports, it will include:

```typescript
// Report status update
{
  screen: 'reportDetails',
  reportId: 'abc123',
  status: 'inProgress',
  type: 'report_update'
}

// New message notification
{
  screen: 'reportDetails',
  reportId: 'abc123',
  openConversation: 'true',
  type: 'new_message'
}
```

## Testing Notifications

To test notification navigation:

1. **Get the device FCM token**:
   ```dart
   String? token = await FirebaseMessaging.instance.getToken();
   print('Device token: $token');
   ```

2. **Send a test notification** using FCM API:
   ```bash
   curl -X POST https://fcm.googleapis.com/fcm/send \
     -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "DEVICE_TOKEN",
       "notification": {
         "title": "Report Update",
         "body": "Your report has been updated"
       },
       "data": {
         "screen": "reportDetails",
         "reportId": "test123",
         "status": "inProgress",
         "type": "report_update"
       }
     }'
   ```

## Best Practices

1. **Keep data fields simple** - Use string values only in the data payload
2. **Use consistent naming** - Match your GoRouter named routes with the screen values
3. **Handle missing data** - Always check if required fields exist before navigating
4. **Test all app states** - Test when app is in foreground, background, and terminated
5. **Provide fallbacks** - Navigate to home if screen or required params are missing

## Troubleshooting

### Common Issues

1. **Navigation not working from cold start**
   - Ensure you check `getInitialMessage()` after Firebase initialization
   - Use `addPostFrameCallback` to wait for the app to be ready

2. **GoRouter not navigating**
   - Make sure route names match exactly
   - Check that path/query parameters are provided correctly
   - Verify your GoRouter is properly initialized before handling notifications

3. **Data fields not received**
   - FCM only supports string values in data payload
   - Ensure all values are strings (use 'true'/'false' for booleans)

### Debug Tips

Add logging to track notification handling:

```dart
void _handleNotificationNavigation(Map<String, dynamic> data) {
  print('=== Notification Navigation ===');
  print('Screen: ${data['screen']}');
  print('Full data: $data');
  
  final screen = data['screen'];
  if (screen == null) {
    print('No screen specified in notification');
    return;
  }
  
  // Your navigation logic...
}
```

## Adding New Notification Types

To add a new notification type:

1. **Admin Panel**: Create a new payload function in `notificationPayloads.ts`:
   ```typescript
   export function createAnnouncementPayload(
     title: string,
     body: string,
     announcementId: string
   ): NotificationPayload {
     return {
       notification: { title, body },
       data: {
         screen: 'announcements',
         announcementId: announcementId,
         type: 'announcement'
       },
       // ... platform configs
     };
   }
   ```

2. **Flutter App**: Add the route to GoRouter and handle in navigation switch:
   ```dart
   case 'announcements':
     context.goNamed(
       'announcements',
       queryParameters: {'id': data['announcementId'] ?? ''},
     );
     break;
   ``` 