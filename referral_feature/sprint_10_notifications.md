# Sprint 10: Notification System for Referral Milestones

**Status**: Not Started
**Previous Sprint**: `sprint_09_share_feature.md`
**Next Sprint**: `sprint_11_revenuecat_rewards.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Implement push notifications and in-app notifications to keep users engaged with referral progress and celebrate milestones.

---

## Prerequisites

### Verify Sprint 09 Completion
- [ ] Share functionality complete
- [ ] Deep links working

### Codebase Checks
1. Check existing Firebase Messaging setup
2. Find notification handling code
3. Check in-app notification/snackbar patterns
4. Look at localization for notifications

---

## Tasks

### Task 1: Define Notification Types

**Notification triggers**:

**For Referrer**:
1. Friend signed up with your code
2. Friend completed a task (e.g., "Sara posted 3 times!")
3. Friend verified (earned progress toward reward)
4. Friend subscribed to Premium (earned bonus)
5. Milestone reached (earned 1 month Premium)
6. Reward ready to redeem

**For Referee**:
1. Welcome notification after using code
2. Task completed reminder
3. Progress update (3/6 tasks done)
4. Verification complete celebration
5. Premium access activated

---

### Task 2: Create Notification Helper Module

**File**: `functions/src/referral/notifications/notificationHelper.ts`

```typescript
interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  data?: { [key: string]: string };
  imageUrl?: string;
}

export async function sendPushNotification(payload: NotificationPayload): Promise<void> {
  // Get user's FCM token from users collection
  // Send via Firebase Admin SDK
  // Handle errors (token invalid, etc.)
}

export async function sendReferralNotification(
  userId: string,
  type: NotificationType,
  data: object
): Promise<void> {
  // Build notification based on type
  // Support bilingual (check user's locale)
  // Send push notification
  // Log notification sent
}

enum NotificationType {
  FRIEND_SIGNED_UP = 'friend_signed_up',
  FRIEND_VERIFIED = 'friend_verified',
  FRIEND_SUBSCRIBED = 'friend_subscribed',
  MILESTONE_REACHED = 'milestone_reached',
  REWARD_READY = 'reward_ready',
  TASK_COMPLETED = 'task_completed',
  VERIFICATION_COMPLETE = 'verification_complete'
}
```

---

### Task 3: Add Notification Triggers to Cloud Functions

**Update existing functions**:

**In `redeemReferralCode.ts`**:
```typescript
// After successful redemption
await sendReferralNotification(referrerId, NotificationType.FRIEND_SIGNED_UP, {
  friendName: userData.displayName
});

await sendReferralNotification(userId, NotificationType.WELCOME, {
  referrerName: referrerData.displayName
});
```

**In checklist tracking functions (Sprint 05)**:
```typescript
// When task completed
await sendReferralNotification(userId, NotificationType.TASK_COMPLETED, {
  taskName: 'Post 3 forum posts',
  progress: '3/6'
});

// Notify referrer of progress
await sendReferralNotification(referrerId, NotificationType.FRIEND_PROGRESS, {
  friendName: userName,
  taskName: 'Posted 3 times'
});
```

**In verification completion handler**:
```typescript
// When verification complete
await sendReferralNotification(userId, NotificationType.VERIFICATION_COMPLETE, {});

await sendReferralNotification(referrerId, NotificationType.FRIEND_VERIFIED, {
  friendName: userName,
  progress: `${verifiedCount}/5`
});

// Check if milestone reached
if (verifiedCount % 5 === 0) {
  await sendReferralNotification(referrerId, NotificationType.MILESTONE_REACHED, {
    reward: '1 month Premium'
  });
}
```

---

### Task 4: Create Notification Templates

**File**: `functions/src/referral/notifications/notificationTemplates.ts`

```typescript
export const notificationTemplates = {
  en: {
    friend_signed_up: {
      title: '🎉 New Referral!',
      body: '{friendName} signed up with your code!'
    },
    friend_verified: {
      title: '✅ Friend Verified!',
      body: '{friendName} completed verification. Progress: {progress} to 1 month free!'
    },
    friend_subscribed: {
      title: '💰 Bonus Earned!',
      body: '{friendName} subscribed to Premium. You earned 2 weeks bonus!'
    },
    milestone_reached: {
      title: '🎁 Reward Unlocked!',
      body: 'You earned {reward}! Tap to redeem.'
    },
    task_completed: {
      title: '✅ Task Completed!',
      body: '{taskName} done. Progress: {progress}'
    },
    verification_complete: {
      title: '🎉 You\'re Verified!',
      body: 'Enjoy 3 days of Premium access. Explore now!'
    }
  },
  ar: {
    // Arabic translations
  }
};

export function buildNotification(
  type: NotificationType,
  locale: string,
  data: object
): { title: string; body: string } {
  const template = notificationTemplates[locale][type];
  // Replace placeholders with data
  return {
    title: replacePlaceholders(template.title, data),
    body: replacePlaceholders(template.body, data)
  };
}
```

---

### Task 5: Handle Notification Clicks (Flutter)

**File**: `lib/core/services/notification_service.dart`

```dart
class NotificationService {
  Future<void> handleNotificationClick(RemoteMessage message) async {
    final type = message.data['type'];
    final navigationService = getIt<NavigationService>();

    switch (type) {
      case 'friend_signed_up':
      case 'friend_verified':
      case 'milestone_reached':
        // Navigate to referral dashboard
        navigationService.navigateTo('/referral-dashboard');
        break;

      case 'task_completed':
      case 'verification_complete':
        // Navigate to checklist progress
        navigationService.navigateTo('/checklist-progress');
        break;

      case 'reward_ready':
        // Navigate to rewards redemption
        navigationService.navigateTo('/referral-dashboard');
        break;

      default:
        // Default action
        navigationService.navigateTo('/home');
    }
  }
}
```

---

### Task 6: Add In-App Notifications

**File**: `lib/features/referral/presentation/widgets/referral_notification_banner.dart`

Show in-app banners for immediate feedback:

```dart
ReferralNotificationBanner:
  "🎉 Your friend Sara just verified!"
  [View Details]
```

Display at top of screen, auto-dismiss after 5 seconds.

---

### Task 7: Create Notification Preferences

**File**: `lib/features/referral/presentation/screens/referral_notification_settings.dart`

Allow users to control notifications:

```
Referral Notifications

✅ New referrals
✅ Friend verified
✅ Milestones reached
❌ Friend progress updates (daily digest)
```

Store preferences in Firestore user document.

---

### Task 8: Implement Notification Grouping

For referrers with many referrals:
- Group notifications: "3 friends made progress today!"
- Prevent spam
- Daily digest option

---

### Task 9: Add Rich Notifications (Optional)

**iOS**: Use notification service extension for images
**Android**: Use BigPictureStyle for celebration images

Add celebration images for milestones.

---

### Task 10: Create Notification Log Collection

**Firestore collection**: `notificationLogs/{logId}`

```typescript
interface NotificationLog {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  sentAt: Timestamp;
  status: 'sent' | 'failed' | 'delivered' | 'opened';
  errorMessage?: string;
}
```

Track delivery and engagement.

---

### Task 11: Add Notification Scheduling

For non-urgent updates, batch and send at optimal times:
- Progress updates: Daily digest at 7 PM
- Milestone reminders: "You're 2 referrals away from 1 month free!"

Use Cloud Scheduler or pub/sub.

---

## Testing Criteria

### Manual Testing
1. **Trigger each notification type**: Use test Cloud Functions
2. **Verify delivery**: Check device receives push
3. **Test clicks**: Tap notification, verify correct navigation
4. **Test localization**: Check Arabic notifications
5. **Test preferences**: Disable a type, verify not received
6. **Test grouping**: Trigger multiple, verify grouped
7. **Test in-app banners**: Verify display and auto-dismiss
8. **Test foreground/background**: Ensure works in both states

### Success Criteria
- [ ] All notification types trigger correctly
- [ ] Push notifications delivered to devices
- [ ] Notification clicks navigate correctly
- [ ] Localization works (English & Arabic)
- [ ] Preferences respected
- [ ] In-app notifications display
- [ ] No spam (proper grouping/throttling)
- [ ] Logs created for tracking
- [ ] Rich notifications work (if implemented)

---

## Edge Cases

1. **No FCM token**: Handle gracefully, log warning
2. **Token expired**: Update token, retry
3. **User disabled notifications**: Don't send push, still show in-app
4. **Multiple devices**: Send to all registered devices
5. **Offline user**: Notifications queue and deliver when online

---

## Analytics

Track notification engagement:

```dart
analytics.logEvent('notification_received', parameters: {
  'type': notificationType,
  'user_type': 'referrer' | 'referee'
});

analytics.logEvent('notification_opened', parameters: {
  'type': notificationType,
  'time_to_open_seconds': 120
});
```

---

## Notes for Next Sprint

Sprint 11 will integrate RevenueCat to actually award Premium access as rewards.

---

**Next Sprint**: `sprint_11_revenuecat_rewards.md`
