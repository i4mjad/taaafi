# Sprint 08: Checklist Progress Tracker UI

**Status**: Not Started
**Previous Sprint**: `sprint_07_referral_dashboard_ui.md`
**Next Sprint**: `sprint_09_share_feature.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Create detailed UI for referred users to track their verification checklist progress. Make it engaging and motivating to complete all tasks.

---

## Prerequisites

### Verify Sprint 07 Completion
- [ ] Referral dashboard UI complete
- [ ] Navigation working

### Codebase Checks
1. Check existing progress indicator widgets
2. Look for checkbox/task list patterns
3. Review onboarding screen designs for inspiration

---

## Tasks

### Task 1: Create Checklist Progress Screen

**File**: `lib/features/referral/presentation/screens/checklist_progress_screen.dart`

**Layout**:
```
┌────────────────────────────────────┐
│ AppBar: "Verification Progress"   │
├────────────────────────────────────┤
│                                    │
│  Progress: 4/6 tasks ●●●●○○       │
│  [━━━━━━━━━━━━○○○○] 67%          │
│                                    │
│  Complete tasks to unlock Premium! │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ✅ Complete Profile          │ │
│  │    Completed 2 days ago      │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ✅ Post 3 Forum Posts        │ │
│  │    3/3 posts                 │ │
│  │    Completed 1 day ago       │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ⏳ 5 Interactions             │ │
│  │    3/5 interactions          │ │
│  │    [Go to Forum]             │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ✅ Join a Group              │ │
│  │    Joined "Support Group"    │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ⏳ Send 3 Group Messages     │ │
│  │    1/3 messages              │ │
│  │    [Go to Group]             │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ⏳ Account Active 7 Days     │ │
│  │    Day 3 of 7                │ │
│  │    4 days remaining          │ │
│  └──────────────────────────────┘ │
│                                    │
│  [What happens next?]             │
│                                    │
└────────────────────────────────────┘
```

---

### Task 2: Create Checklist Item Widget

**File**: `lib/features/referral/presentation/widgets/checklist_item_widget.dart`

**States**:
- **Completed**: Green checkmark, grey text, timestamp
- **In Progress**: Yellow clock, progress indicator, action button
- **Not Started**: Grey circle, grey text

**Features**:
- Icon based on status
- Title and description
- Progress indicator (e.g., "3/5")
- Action button to navigate to relevant feature
- Timestamp for completed items

---

### Task 3: Create Progress Header Widget

**File**: `lib/features/referral/presentation/widgets/verification_progress_header.dart`

**Display**:
- Overall progress percentage
- Visual progress bar
- Dots indicator (●●●●○○)
- Motivational text: "You're almost there!" or "Great progress!"

---

### Task 4: Add Real-Time Updates

Use Firestore real-time listeners:

```dart
final checklistProgressProvider = StreamProvider.autoDispose<ReferralVerification?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return db.collection('referralVerifications').doc(userId).snapshots()
    .map((snap) => snap.exists ? ReferralVerification.fromFirestore(snap) : null);
});
```

Updates UI automatically when progress changes.

---

### Task 5: Add Action Buttons

Each incomplete task has contextual action:

```dart
TaskActionButton:
  - "Post 3 Forum Posts" → Navigate to Create Post screen
  - "5 Interactions" → Navigate to Forum feed
  - "Join a Group" → Navigate to Groups list
  - "Send 3 Group Messages" → Navigate to user's group chat
  - "Start 1 Activity" → Navigate to Activities list
  - "Account Active 7 Days" → No action (automatic)
```

---

### Task 6: Add Completion Celebration

When all tasks complete:

**File**: `lib/features/referral/presentation/widgets/verification_complete_widget.dart`

**Display**:
```
┌────────────────────────────────┐
│      🎉 Congratulations! 🎉   │
│                                │
│  You're verified!              │
│  You've unlocked 3 days        │
│  Premium access!               │
│                                │
│  [Explore Premium Features]    │
└────────────────────────────────┘
```

With confetti animation or celebration graphic.

---

### Task 7: Add Referrer Info Card

Show who referred them:

```dart
ReferrerInfoCard:
  "You were referred by Ahmad"
  "Complete tasks to help them unlock rewards too!"
```

Adds social motivation.

---

### Task 8: Create "What Happens Next" Info Sheet

Bottom sheet explaining:
```
What Happens After Verification?

✅ You get 3 days Premium access
   Enjoy all premium features!

🎁 Your friend earns progress
   They get closer to 1 month free

📱 Continue using the app
   Your Premium access starts immediately

💰 Subscribe for more
   Love Premium? Subscribe and give your
   friend a 2-week bonus!
```

---

### Task 9: Add Notifications Prompt

When task completed, show subtle notification:

```dart
SnackBar:
  "✅ Task completed! 4/6 done. Keep going!"
```

Use app's notification/snackbar system.

---

### Task 10: Handle Edge Cases

**Blocked users**:
```
Your verification is under review.
Our team will contact you soon.
```

**Inactive referrer** (deleted account):
```
Your referrer's account is no longer active,
but you can still complete verification
to unlock Premium!
```

---

### Task 11: Add Analytics

Track events:
```dart
// When screen viewed
analytics.logEvent('checklist_progress_viewed');

// When task action button tapped
analytics.logEvent('checklist_task_action_tapped', parameters: {
  'task': 'forum_posts',
  'progress': '2/3'
});

// When verification completed
analytics.logEvent('checklist_verification_completed', parameters: {
  'duration_days': 5
});
```

---

## Testing Criteria

### Manual Testing
1. **As referred user**: Complete signup with referral code
2. Navigate to checklist progress screen
3. Verify all 6 tasks display correctly
4. Complete one task (e.g., create post)
5. Verify progress updates in real-time
6. Tap action buttons, verify correct navigation
7. Complete all tasks
8. Verify celebration screen shows
9. Test with blocked user (manually block in Firestore)
10. Test Arabic localization

### Success Criteria
- [ ] Progress screen shows all checklist items
- [ ] Real-time updates work correctly
- [ ] Action buttons navigate properly
- [ ] Progress indicators accurate
- [ ] Completion celebration shows
- [ ] Blocked state handled gracefully
- [ ] Smooth animations
- [ ] Localized in both languages

---

## Localization Keys

```json
{
  "referral.checklist.title": "Verification Progress",
  "referral.checklist.progress": "{completed} of {total} tasks",
  "referral.checklist.subtitle": "Complete tasks to unlock Premium!",
  "referral.checklist.complete_profile": "Complete Profile",
  "referral.checklist.forum_posts": "Post 3 Forum Posts",
  "referral.checklist.interactions": "5 Interactions",
  "referral.checklist.join_group": "Join a Group",
  "referral.checklist.group_messages": "Send 3 Group Messages",
  "referral.checklist.account_age": "Account Active 7 Days",
  "referral.checklist.start_activity": "Start 1 Recovery Activity",
  "referral.checklist.completed": "Completed",
  "referral.checklist.in_progress": "In Progress",
  "referral.checklist.not_started": "Not Started",
  "referral.checklist.go_to_forum": "Go to Forum",
  "referral.checklist.go_to_groups": "Go to Groups",
  "referral.checklist.days_remaining": "{days} days remaining",
  "referral.checklist.referred_by": "Referred by {name}",
  "referral.checklist.celebration_title": "Congratulations!",
  "referral.checklist.celebration_message": "You're verified! Enjoy 3 days Premium access.",
  "referral.checklist.under_review": "Your verification is under review."
}
```

---

## Design Guidelines

- **Clear progress**: Always show where they are in the journey
- **Actionable**: Make it obvious what to do next
- **Encouraging**: Use positive language
- **Not overwhelming**: Don't show too much at once

---

## Notes for Next Sprint

Sprint 09 will enhance share functionality with templates and deep links.

---

**Next Sprint**: `sprint_09_share_feature.md`
