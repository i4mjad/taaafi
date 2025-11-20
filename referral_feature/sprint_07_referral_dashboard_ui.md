# Sprint 07: User Referral Dashboard UI

**Status**: Not Started
**Previous Sprint**: `sprint_06_fraud_detection.md`
**Next Sprint**: `sprint_08_checklist_progress_ui.md`
**Estimated Duration**: 8-10 hours

---

## Objectives
Create a beautiful, engaging referral dashboard UI in the Flutter app where users can view their referral code, stats, and rewards.

---

## Prerequisites

### Verify Sprint 06 Completion
- [ ] Fraud detection working
- [ ] All backend systems functional

### Codebase Checks
1. Find Settings or Profile screen location
2. Check UI component library and design system
3. Examine existing card/widget patterns
4. Review color scheme and typography
5. Check share functionality implementation

---

## Tasks

### Task 1: Create Referral Dashboard Screen

**File**: `lib/features/referral/presentation/screens/referral_dashboard_screen.dart`

**Layout Structure**:
```
┌────────────────────────────────────┐
│ AppBar: "Referral Program"        │
├────────────────────────────────────┤
│                                    │
│  ┌──────────────────────────────┐ │
│  │  Your Referral Code          │ │
│  │  ┌────────────────────────┐  │ │
│  │  │     AHMAD7    [Share]  │  │ │
│  │  └────────────────────────┘  │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │  Referral Stats              │ │
│  │  👥 5 Total Referrals        │ │
│  │  ✅ 3 Verified               │ │
│  │  💰 1 Paid Conversion        │ │
│  │  ⏳ 1 Pending                │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │  Rewards Earned              │ │
│  │  🎁 2 Months Premium         │ │
│  │  📅 Next reward at 5 users   │ │
│  │                              │ │
│  │  [Redeem Rewards]            │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │  Your Referrals              │ │
│  │  • Sara ✅ Verified          │ │
│  │  • Khaled ⏳ Pending (3/6)   │ │
│  │  • Noor 💰 Premium           │ │
│  └──────────────────────────────┘ │
│                                    │
│  [How it Works]                   │
│                                    │
└────────────────────────────────────┘
```

---

### Task 2: Create Referral Code Card Widget

**File**: `lib/features/referral/presentation/widgets/referral_code_card.dart`

**Features**:
- Display code in large, readable font
- Copy-to-clipboard button
- Share button (WhatsApp, SMS, general share)
- Subtle animation to draw attention
- Gradient background (not too noisy)

**Localization**:
```json
{
  "referral.dashboard.your_code": "Your Referral Code",
  "referral.dashboard.code_copied": "Code copied to clipboard!",
  "referral.dashboard.share_code": "Share Code"
}
```

---

### Task 3: Create Stats Card Widget

**File**: `lib/features/referral/presentation/widgets/referral_stats_card.dart`

**Display**:
- Total referrals (totalReferred)
- Verified users (totalVerified)
- Paid conversions (totalPaidConversions)
- Pending verifications (pendingVerifications)

Use icons and colors to make it visually appealing.

---

### Task 4: Create Rewards Card Widget

**File**: `lib/features/referral/presentation/widgets/rewards_card.dart`

**Features**:
- Show total rewards earned (months + weeks)
- Progress bar to next milestone
- "Redeem" button (if rewards available)
- Empty state if no rewards yet

**Logic**:
- Calculate: `totalVerified / 5` = months earned
- Calculate: `totalPaidConversions * 2` = weeks earned
- Show next milestone: "2 more referrals to unlock 1 month!"

---

### Task 5: Create Referral List Widget

**File**: `lib/features/referral/presentation/widgets/referral_list_widget.dart`

**Show list of referred users**:
- User's display name (or "User" + number for privacy)
- Status icon: ✅ Verified, ⏳ Pending, 💰 Premium, 🚫 Blocked
- Progress indicator for pending (e.g., "3/6 tasks complete")
- Tap to see detailed progress (links to Sprint 08)

**Privacy consideration**: Don't show too much detail about referred users.

---

### Task 6: Create "How It Works" Bottom Sheet

**File**: `lib/features/referral/presentation/widgets/how_it_works_sheet.dart`

**Content**:
```
How Referral Program Works

1️⃣ Share Your Code
   Share your unique code with friends

2️⃣ They Join & Verify
   New users complete simple activities:
   • Be active for 7 days
   • Post 3 forum posts
   • Interact 5 times
   • Join a group & send 3 messages
   • Start 1 recovery activity

3️⃣ You Earn Rewards
   • Every 5 verified users = 1 month Premium
   • When they subscribe = +2 weeks bonus

[Got it]
```

Localized in both English and Arabic.

---

### Task 7: Create State Management Providers

**File**: `lib/features/referral/presentation/providers/referral_dashboard_provider.dart`

Using Riverpod:
```dart
// Provider for user's referral code
final userReferralCodeProvider = FutureProvider<ReferralCodeModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(referralRepositoryProvider).getUserReferralCode(userId);
});

// Provider for referral stats
final referralStatsProvider = FutureProvider<ReferralStatsModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(referralRepositoryProvider).getReferralStats(userId);
});

// Provider for referred users list
final referredUsersProvider = FutureProvider<List<ReferralVerification>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(referralRepositoryProvider).getReferredUsers(userId);
});
```

---

### Task 8: Add Navigation to Dashboard

Add referral dashboard to:
1. **Settings/Profile screen**: Add "Referral Program" menu item
2. **Bottom navigation** (optional): If prominent feature
3. **Home screen**: Show banner/card promoting referrals

**Navigation route**:
```dart
GoRoute(
  path: '/referral-dashboard',
  name: 'referral-dashboard',
  builder: (context, state) => const ReferralDashboardScreen(),
)
```

---

### Task 9: Share Functionality

**File**: Update repository with share helper

```dart
Future<void> shareReferralCode(String code, String userId) async {
  final message = _buildShareMessage(code);

  // Use share_plus package
  await Share.share(
    message,
    subject: 'Join me on Ta3afi',
  );

  // Log analytics
  analytics.logEvent('referral_code_shared', parameters: {'method': 'general'});
}

String _buildShareMessage(String code) {
  return '''
Join me on Ta3afi for recovery support!

Use my code: $code
Get 3 days Premium free when you verify your account.

Download: [App Store / Play Store links]
''';
}
```

Support WhatsApp direct share if possible.

---

### Task 10: Add Empty States

Handle cases:
- **No referral code yet**: Show loading or error
- **No referrals**: Show motivational message "Share your code to get started!"
- **No rewards yet**: Show progress to first reward

---

### Task 11: Add Animations

Subtle animations:
- Fade in when screen loads
- Pulse animation on "Share" button
- Celebration animation when milestone reached (confetti?)
- Progress bar animations

Use `flutter_animate` or similar package.

---

## Testing Criteria

### UI Tests
1. **Widget Tests**: Test each widget renders correctly
2. **Golden Tests**: Snapshot tests for visual regression
3. **Responsive**: Test on different screen sizes

### Manual Testing
1. Open referral dashboard
2. Verify code displays correctly
3. Test share functionality (WhatsApp, SMS, general)
4. Verify stats match Firestore data
5. Test "How it Works" sheet
6. Test navigation from Settings
7. Test empty states
8. Test Arabic localization
9. Test animations smooth and not annoying

### Success Criteria
- [ ] Dashboard screen beautiful and engaging
- [ ] All widgets render correctly
- [ ] Share functionality works
- [ ] Stats accurate and real-time
- [ ] Navigation integrated
- [ ] Animations smooth
- [ ] Localized in English and Arabic
- [ ] Accessible (screen reader support)
- [ ] No performance issues

---

## Design Guidelines

### Visual Style
- **Clean and minimal**: Don't overwhelm user
- **Celebratory**: Use positive colors and icons
- **Clear hierarchy**: Most important info prominent
- **Consistent**: Match existing app design

### Colors
- Use app's primary colors
- Success green for verified
- Warning yellow for pending
- Error red for blocked (if shown)

### Typography
- Large, bold code display
- Clear section headers
- Readable body text

### Accessibility
- Proper semantic labels
- Screen reader support
- High contrast text
- Touch targets >= 48px

---

## Notes for Next Sprint

Sprint 08 will add detailed checklist progress tracking UI. Dashboard provides overview, Sprint 08 provides detail.

---

**Next Sprint**: `sprint_08_checklist_progress_ui.md`
