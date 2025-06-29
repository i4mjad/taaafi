# Group Subscription Tracking Guide

## Overview
This guide explains how to track user subscriptions to messaging groups in Firestore when users subscribe to FCM topics.

## Firestore Data Structure

### Collections Required

#### 1. `usersMessagingGroups` Collection
```javascript
usersMessagingGroups/{groupId}
├── name: "All Users"
├── nameAr: "جميع المستخدمين"
├── description: "Default group for all users"
├── descriptionAr: "المجموعة الافتراضية لجميع المستخدمين"
├── topicId: "all_users"
├── memberCount: 1250                    // ← Track total subscribers
├── isActive: true
├── createdAt: timestamp
└── updatedAt: timestamp
```

#### 2. `userGroupMemberships` Collection
```javascript
userGroupMemberships/{userId}
├── userId: "user123"
├── groups: [
│   {
│     groupId: "group_abc123",
│     groupName: "All Users",
│     groupNameAr: "جميع المستخدمين",
│     topicId: "all_users",
│     subscribedAt: timestamp            // ← Track when user subscribed
│   },
│   {
│     groupId: "group_def456",
│     groupName: "Premium Users",
│     groupNameAr: "المستخدمون المميزون",
│     topicId: "premium_users",
│     subscribedAt: timestamp
│   }
│ ]
└── updatedAt: timestamp
```

## Implementation Steps

### Step 1: Subscribe User to Group

```dart
Future<bool> subscribeUserToGroup(String userId, String groupId) async {
  try {
    // Use Firestore transaction for atomic operations
    return await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
      
      // 1. Get group information
      final groupRef = FirebaseFirestore.instance
          .collection('usersMessagingGroups')
          .doc(groupId);
      final groupDoc = await transaction.get(groupRef);
      
      if (!groupDoc.exists || !(groupDoc.data()!['isActive'] ?? true)) {
        throw Exception('Group not found or inactive');
      }
      
      final groupData = groupDoc.data()!;

      // 2. Get user's current memberships
      final userMembershipsRef = FirebaseFirestore.instance
          .collection('userGroupMemberships')
          .doc(userId);
      final userMembershipsDoc = await transaction.get(userMembershipsRef);
      
      List<Map<String, dynamic>> currentGroups = [];
      if (userMembershipsDoc.exists) {
        final data = userMembershipsDoc.data();
        if (data != null && data['groups'] != null) {
          currentGroups = List<Map<String, dynamic>>.from(data['groups']);
        }
      }

      // 3. Check if already subscribed
      bool alreadySubscribed = currentGroups.any(
        (group) => group['groupId'] == groupId,
      );
      
      if (alreadySubscribed) {
        return true; // Already subscribed
      }

      // 4. Add new group subscription
      final newGroup = {
        'groupId': groupId,
        'groupName': groupData['name'] ?? '',
        'groupNameAr': groupData['nameAr'] ?? '',
        'topicId': groupData['topicId'] ?? '',
        'subscribedAt': FieldValue.serverTimestamp(),
      };
      
      currentGroups.add(newGroup);

      // 5. Update user's group memberships
      transaction.set(
        userMembershipsRef,
        {
          'userId': userId,
          'groups': currentGroups,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 6. Increment group member count
      transaction.update(groupRef, {
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  } catch (e) {
    print('Error subscribing user to group: $e');
    return false;
  }
}
```

### Step 2: Auto-Subscribe to "all_users" Group

```dart
Future<void> autoSubscribeToAllUsersGroup(String userId) async {
  try {
    // Find the "all_users" group
    final allUsersQuery = await FirebaseFirestore.instance
        .collection('usersMessagingGroups')
        .where('topicId', isEqualTo: 'all_users')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (allUsersQuery.docs.isNotEmpty) {
      final allUsersGroupId = allUsersQuery.docs.first.id;
      
      // Subscribe user to the group
      bool success = await subscribeUserToGroup(userId, allUsersGroupId);
      
      if (success) {
        // Also subscribe to FCM topic
        await FirebaseMessaging.instance.subscribeToTopic('all_users');
        print('User auto-subscribed to all_users group');
      }
    }
  } catch (e) {
    print('Error auto-subscribing to all_users: $e');
  }
}
```

### Step 3: Call During User Authentication

```dart
// In your authentication flow
FirebaseAuth.instance.authStateChanges().listen((User? user) async {
  if (user != null) {
    // User signed in - auto-subscribe to all_users group
    await autoSubscribeToAllUsersGroup(user.uid);
  }
});
```

## Key Benefits

1. **📊 Accurate Analytics**: Track exactly who is subscribed to each group
2. **📅 Subscription History**: Know when each user subscribed
3. **🔢 Member Counts**: Maintain accurate group member counts
4. **⚛️ Data Consistency**: Atomic operations prevent data corruption
5. **🔍 Query Capabilities**: Easy to query user subscriptions and group memberships

## Usage Examples

### Get User's Subscriptions
```dart
Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId) async {
  final doc = await FirebaseFirestore.instance
      .collection('userGroupMemberships')
      .doc(userId)
      .get();

  if (!doc.exists) return [];
  
  return List<Map<String, dynamic>>.from(doc.data()!['groups'] ?? []);
}
```

### Check if User is Subscribed to Group
```dart
Future<bool> isUserSubscribedToGroup(String userId, String groupId) async {
  final subscriptions = await getUserSubscriptions(userId);
  return subscriptions.any((group) => group['groupId'] == groupId);
}
```

### Get Group Member Count
```dart
Future<int> getGroupMemberCount(String groupId) async {
  final doc = await FirebaseFirestore.instance
      .collection('usersMessagingGroups')
      .doc(groupId)
      .get();
      
  return doc.exists ? (doc.data()!['memberCount'] ?? 0) : 0;
}
```

## Important Notes

- Always use Firestore transactions for subscription operations
- Check if user is already subscribed before adding
- Handle both Firestore tracking AND FCM topic subscription
- Increment/decrement group member counts atomically
- Store subscription timestamp for analytics 