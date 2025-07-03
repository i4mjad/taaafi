# Firebase User Ban & Warning System Integration Guide

## Overview

This guide provides comprehensive instructions for integrating the new user ban and warning system in your Flutter app with Firebase Firestore. The system allows for granular control over user access through warnings and different types of bans.

## Firestore Collections Structure

### 1. Warnings Collection (`warnings`)

```json
{
  "id": "auto-generated-document-id",
  "userId": "string",
  "type": "content_violation | inappropriate_behavior | spam | harassment | other",
  "reason": "string",
  "description": "string | null",
  "severity": "low | medium | high | critical",
  "issuedBy": "string (admin email)",
  "issuedAt": "Timestamp",
  "expiresAt": "Timestamp | null",
  "isActive": "boolean",
  "relatedContent": "string | null"
}
```

### 2. Bans Collection (`bans`)

```json
{
  "id": "auto-generated-document-id",
  "userId": "string",
  "type": "user_ban | device_ban | feature_ban",
  "scope": "app_wide | feature_specific",
  "reason": "string",
  "description": "string | null",
  "severity": "temporary | permanent",
  "issuedBy": "string (admin email)",
  "issuedAt": "Timestamp",
  "expiresAt": "Timestamp | null",
  "isActive": "boolean",
  "restrictedFeatures": "array of feature uniqueNames | null",
  "restrictedDevices": "array of device IDs | null",
  "relatedContent": "string | null"
}
```

### 3. Features Collection (`features`)

```json
{
  "id": "auto-generated-document-id",
  "uniqueName": "string (generated from English name)",
  "nameEn": "string",
  "nameAr": "string",
  "descriptionEn": "string",
  "descriptionAr": "string",
  "category": "core | social | content | communication | settings",
  "iconName": "string",
  "isActive": "boolean",
  "isBannable": "boolean",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Flutter Integration

### 1. Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  shared_preferences: ^2.2.2
```

### 2. Models

#### Warning Model

```dart
class Warning {
  final String id;
  final String userId;
  final WarningType type;
  final String reason;
  final String? description;
  final WarningSeverity severity;
  final String issuedBy;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? relatedContent;

  Warning({
    required this.id,
    required this.userId,
    required this.type,
    required this.reason,
    this.description,
    required this.severity,
    required this.issuedBy,
    required this.issuedAt,
    this.expiresAt,
    required this.isActive,
    this.relatedContent,
  });

  factory Warning.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Warning(
      id: doc.id,
      userId: data['userId'],
      type: WarningType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
      ),
      reason: data['reason'],
      description: data['description'],
      severity: WarningSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
      ),
      issuedBy: data['issuedBy'],
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'],
      relatedContent: data['relatedContent'],
    );
  }

  bool get isExpired => 
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

enum WarningType {
  content_violation,
  inappropriate_behavior,
  spam,
  harassment,
  other
}

enum WarningSeverity {
  low,
  medium,
  high,
  critical
}
```

#### Ban Model

```dart
class Ban {
  final String id;
  final String userId;
  final BanType type;
  final BanScope scope;
  final String reason;
  final String? description;
  final BanSeverity severity;
  final String issuedBy;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String>? restrictedFeatures;
  final List<String>? restrictedDevices;
  final String? relatedContent;

  Ban({
    required this.id,
    required this.userId,
    required this.type,
    required this.scope,
    required this.reason,
    this.description,
    required this.severity,
    required this.issuedBy,
    required this.issuedAt,
    this.expiresAt,
    required this.isActive,
    this.restrictedFeatures,
    this.restrictedDevices,
    this.relatedContent,
  });

  factory Ban.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ban(
      id: doc.id,
      userId: data['userId'],
      type: BanType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
      ),
      scope: BanScope.values.firstWhere(
        (e) => e.toString().split('.').last == data['scope'],
      ),
      reason: data['reason'],
      description: data['description'],
      severity: BanSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
      ),
      issuedBy: data['issuedBy'],
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'],
      restrictedFeatures: data['restrictedFeatures'] != null 
          ? List<String>.from(data['restrictedFeatures']) 
          : null,
      restrictedDevices: data['restrictedDevices'] != null 
          ? List<String>.from(data['restrictedDevices']) 
          : null,
      relatedContent: data['relatedContent'],
    );
  }

  bool get isExpired => 
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

enum BanType {
  user_ban,
  device_ban,
  feature_ban
}

enum BanScope {
  app_wide,
  feature_specific
}

enum BanSeverity {
  temporary,
  permanent
}
```

#### App Feature Model

```dart
class AppFeature {
  final String id;
  final String uniqueName;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final FeatureCategory category;
  final String iconName;
  final bool isActive;
  final bool isBannable;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppFeature({
    required this.id,
    required this.uniqueName,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.category,
    required this.iconName,
    required this.isActive,
    required this.isBannable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppFeature.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppFeature(
      id: doc.id,
      uniqueName: data['uniqueName'],
      nameEn: data['nameEn'],
      nameAr: data['nameAr'],
      descriptionEn: data['descriptionEn'],
      descriptionAr: data['descriptionAr'],
      category: FeatureCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
      ),
      iconName: data['iconName'],
      isActive: data['isActive'],
      isBannable: data['isBannable'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}

enum FeatureCategory {
  core,
  social,
  content,
  communication,
  settings
}
```

### 3. Ban & Warning Service

```dart
class BanWarningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's active warnings
  Future<List<Warning>> getUserWarnings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('warnings')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Warning.fromFirestore(doc))
          .where((warning) => !warning.isExpired)
          .toList();
    } catch (e) {
      print('Error fetching warnings: $e');
      return [];
    }
  }

  // Get user's active bans
  Future<List<Ban>> getUserBans(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Ban.fromFirestore(doc))
          .where((ban) => !ban.isExpired)
          .toList();
    } catch (e) {
      print('Error fetching bans: $e');
      return [];
    }
  }

  // Check if user is banned from a specific feature
  Future<bool> isUserBannedFromFeature(String userId, String featureUniqueName) async {
    final bans = await getUserBans(userId);
    
    for (final ban in bans) {
      // Check for app-wide bans
      if (ban.scope == BanScope.app_wide) {
        return true;
      }
      
      // Check for feature-specific bans
      if (ban.scope == BanScope.feature_specific && 
          ban.restrictedFeatures != null &&
          ban.restrictedFeatures!.contains(featureUniqueName)) {
        return true;
      }
    }
    
    return false;
  }

  // Check if device is banned
  Future<bool> isDeviceBanned(String deviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bans')
          .where('type', isEqualTo: 'device_ban')
          .where('isActive', isEqualTo: true)
          .where('restrictedDevices', arrayContains: deviceId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking device ban: $e');
      return false;
    }
  }

  // Get app features
  Future<List<AppFeature>> getAppFeatures() async {
    try {
      final querySnapshot = await _firestore
          .collection('features')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('nameEn')
          .get();

      return querySnapshot.docs
          .map((doc) => AppFeature.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching app features: $e');
      return [];
    }
  }

  // Check user access before performing actions
  Future<bool> canUserPerformAction(String featureUniqueName) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if user is banned from this feature
    return !(await isUserBannedFromFeature(user.uid, featureUniqueName));
  }
}
```

### 4. Device ID Management

```dart
class DeviceService {
  static const String _deviceIdKey = 'device_id';
  
  // Generate and store device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }
  
  static String _generateDeviceId() {
    // Generate unique device ID (can be combined with device info)
    return 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }
  
  // Store device ID in user profile
  static Future<void> registerDeviceForUser(String userId, String deviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'devicesIds': FieldValue.arrayUnion([deviceId])
      });
    } catch (e) {
      print('Error registering device: $e');
    }
  }
}
```

### 5. Usage Examples

#### Check Feature Access

```dart
class MessagingService {
  final BanWarningService _banWarningService = BanWarningService();
  
  Future<bool> sendMessage(String message) async {
    // Check if user can use messaging feature
    if (!(await _banWarningService.canUserPerformAction('direct_messaging'))) {
      throw Exception('You are banned from using the messaging feature');
    }
    
    // Proceed with sending message
    // ... rest of messaging logic
    return true;
  }
}
```

#### App Startup Check

```dart
class AppInitializationService {
  final BanWarningService _banWarningService = BanWarningService();
  
  Future<bool> checkUserAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;
    
    // Get device ID
    final deviceId = await DeviceService.getDeviceId();
    
    // Check if device is banned
    if (await _banWarningService.isDeviceBanned(deviceId)) {
      // Show device ban message and prevent app usage
      return false;
    }
    
    // Check for app-wide user bans
    final bans = await _banWarningService.getUserBans(user.uid);
    final appWideBan = bans.firstWhere(
      (ban) => ban.scope == BanScope.app_wide,
      orElse: () => null,
    );
    
    if (appWideBan != null) {
      // Show ban message and prevent app usage
      return false;
    }
    
    return true;
  }
}
```

#### Warning Display

```dart
class WarningWidget extends StatelessWidget {
  final String userId;
  
  const WarningWidget({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Warning>>(
      future: BanWarningService().getUserWarnings(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }
        
        final warnings = snapshot.data!;
        final highPriorityWarnings = warnings
            .where((w) => w.severity == WarningSeverity.high || 
                        w.severity == WarningSeverity.critical)
            .toList();
        
        if (highPriorityWarnings.isEmpty) return SizedBox.shrink();
        
        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Active Warnings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ...highPriorityWarnings.map((warning) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${warning.reason}',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
```

## Security Rules

Add these Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Warnings - read-only for users, admin-only write
    match /warnings/{warningId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
    
    // Bans - read-only for users, admin-only write  
    match /bans/{banId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
    
    // Features - read-only for all authenticated users
    match /features/{featureId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
  }
}
```

## Integration Checklist

- [ ] Add dependencies to pubspec.yaml
- [ ] Implement Warning, Ban, and AppFeature models
- [ ] Create BanWarningService class
- [ ] Implement DeviceService for device tracking
- [ ] Add device registration on app startup
- [ ] Check feature access before sensitive operations
- [ ] Display warnings to users appropriately
- [ ] Test ban enforcement for different ban types
- [ ] Implement proper error handling
- [ ] Add Firestore security rules
- [ ] Test offline behavior
- [ ] Add logging for audit purposes

## Best Practices

1. **Caching**: Cache ban/warning status locally but refresh periodically
2. **Offline Handling**: Store last known ban status for offline functionality
3. **Performance**: Use indexed queries and appropriate pagination
4. **User Experience**: Provide clear messages about restrictions
5. **Security**: Always verify server-side before allowing actions
6. **Logging**: Log all access attempts for audit purposes
7. **Testing**: Implement comprehensive testing for all ban scenarios

## Support

For questions about implementing this system, please refer to:
- Firebase Firestore documentation
- Flutter Firebase plugins documentation
- Admin panel user management section

---

**Note**: Remember to handle all edge cases and provide appropriate user feedback for banned features. Always verify restrictions server-side for security. 