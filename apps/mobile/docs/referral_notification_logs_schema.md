# Referral Notification Logs Schema

## Collection: `notificationLogs`

This collection tracks all referral notifications sent to users for monitoring, debugging, and analytics.

### Document Structure

```typescript
{
  userId: string;              // User ID who received the notification
  type: NotificationType;      // Type of notification (enum)
  category: 'referral';        // Always 'referral' for these logs
  message: string;             // The notification body or error message
  status: 'sent' | 'failed' | 'delivered' | 'opened';
  sentAt: Timestamp;           // When notification was sent
  createdAt: Timestamp;        // Document creation timestamp
}
```

### Notification Types

#### For Referrer:
- `friend_signed_up` - Friend signed up using their code
- `friend_task_progress` - Friend completed a verification task
- `friend_verified` - Friend completed verification
- `friend_subscribed` - Friend subscribed to Premium (bonus earned)
- `milestone_reached` - Referrer reached a milestone (5 verifications)
- `reward_ready` - Reward is ready to claim

#### For Referee:
- `welcome` - Welcome message after using referral code
- `task_completed` - User completed a verification task
- `progress_update` - Progress update on verification
- `verification_complete` - User completed all verification requirements
- `premium_activated` - Premium access activated

### Example Document

```json
{
  "userId": "abc123xyz",
  "type": "friend_verified",
  "category": "referral",
  "message": "John Doe completed verification. Progress: 3/5 verified!",
  "status": "sent",
  "sentAt": "2025-11-21T10:30:00Z",
  "createdAt": "2025-11-21T10:30:00Z"
}
```

### Firestore Security Rules

```javascript
match /notificationLogs/{logId} {
  // Only allow system (Cloud Functions) to write
  allow write: if false;
  
  // Users can read their own notification logs
  allow read: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
}
```

### Indexes

**Composite Index:**
```
Collection: notificationLogs
Fields: userId (Ascending), sentAt (Descending)
```

This allows efficient querying of user's notification history ordered by time.

### Usage

#### Query user's notification history:
```dart
final logs = await FirebaseFirestore.instance
  .collection('notificationLogs')
  .where('userId', isEqualTo: userId)
  .orderBy('sentAt', descending: true)
  .limit(50)
  .get();
```

#### Query failed notifications:
```dart
final failedLogs = await FirebaseFirestore.instance
  .collection('notificationLogs')
  .where('status', isEqualTo: 'failed')
  .where('sentAt', isGreaterThan: DateTime.now().subtract(Duration(days: 7)))
  .get();
```

### Analytics Use Cases

1. **Delivery Rate**: Track sent vs failed notifications
2. **User Engagement**: Monitor which notification types get opened
3. **Debugging**: Investigate notification delivery issues
4. **Performance**: Measure notification delivery times

### Retention Policy

Consider implementing a Cloud Function to:
- Archive logs older than 90 days
- Delete logs older than 1 year
- Keep only failed notifications for longer periods

### Notes

- Logs are created automatically by Cloud Functions
- No user-facing UI is required for logs (admin panel only)
- Logs help with debugging FCM token issues
- Can be used for analytics and reporting

