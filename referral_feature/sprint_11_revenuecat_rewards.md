# Sprint 11: RevenueCat Reward Integration

**Status**: ✅ Completed
**Previous Sprint**: `sprint_10_notifications.md`
**Next Sprint**: `sprint_12_admin_dashboard.md`
**Estimated Duration**: 8-10 hours

---

## Objectives
Integrate with RevenueCat to automatically grant Premium subscriptions as rewards. Handle reward redemption, expiration, and paid conversion bonuses.

---

## Prerequisites

### Verify Sprint 10 Completion
- [ ] Notification system working
- [ ] All mobile features complete

### Codebase Checks
1. Find existing RevenueCat integration code
2. Check how `isPlusUser` is currently managed
3. Look for existing subscription management
4. Check RevenueCat API keys and configuration
5. Find customer ID management

---

## Tasks

### Task 1: Research RevenueCat Promotional Entitlements

**Key questions**:
- Can RevenueCat grant time-limited entitlements programmatically?
- API endpoint for granting promotional access
- How to track promotional vs. paid subscriptions
- Expiration handling

**Documentation**: RevenueCat Promotional Entitlements API

---

### Task 2: Create RevenueCat Helper Module (Cloud Functions)

**File**: `functions/src/referral/revenuecat/revenuecatHelper.ts`

```typescript
import axios from 'axios';

const REVENUECAT_API_KEY = functions.config().revenuecat.api_key;
const REVENUECAT_BASE_URL = 'https://api.revenuecat.com/v1';

export async function grantPromotionalEntitlement(
  userId: string,
  durationDays: number
): Promise<{ success: boolean; expiresAt: Date }> {
  // Get user's RevenueCat customer ID
  // Calculate expiration date
  // Call RevenueCat API to grant entitlement
  // Return result
}

export async function getSubscriptionStatus(userId: string): Promise<object> {
  // Query RevenueCat for user's subscription status
  // Return active entitlements
}

export async function revokePromotionalEntitlement(userId: string): Promise<void> {
  // Remove promotional entitlement (if needed for fraud cases)
}
```

---

### Task 3: Implement Reward Calculation Logic

**File**: `functions/src/referral/rewards/rewardCalculator.ts`

```typescript
export interface RewardCalculation {
  totalVerified: number;
  totalPaidConversions: number;
  monthsEarned: number;
  weeksEarned: number;
  totalDays: number;
  unredeemed: boolean;
}

export async function calculateUserRewards(userId: string): Promise<RewardCalculation> {
  const stats = await getReferralStats(userId);

  const monthsEarned = Math.floor(stats.totalVerified / 5);
  const weeksEarned = stats.totalPaidConversions * 2;
  const totalDays = (monthsEarned * 30) + (weeksEarned * 7);

  // Check if already redeemed
  const alreadyRedeemed = await checkIfRewardRedeemed(userId, totalDays);

  return {
    totalVerified: stats.totalVerified,
    totalPaidConversions: stats.totalPaidConversions,
    monthsEarned,
    weeksEarned,
    totalDays,
    unredeemed: !alreadyRedeemed
  };
}
```

---

### Task 4: Create Reward Redemption Cloud Function

**File**: `functions/src/referral/rewards/redeemRewards.ts`

```typescript
export const redeemReferralRewards = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  const userId = context.auth.uid;

  // Calculate rewards
  const rewards = await calculateUserRewards(userId);

  if (rewards.totalDays === 0) {
    throw new functions.https.HttpsError('failed-precondition', 'No rewards to redeem');
  }

  if (!rewards.unredeemed) {
    throw new functions.https.HttpsError('failed-precondition', 'Rewards already redeemed');
  }

  // Grant promotional entitlement via RevenueCat
  const result = await grantPromotionalEntitlement(userId, rewards.totalDays);

  if (!result.success) {
    throw new functions.https.HttpsError('internal', 'Failed to grant rewards');
  }

  // Log reward redemption
  await db.collection('referralRewards').add({
    referrerId: userId,
    type: 'verification_milestone',
    amount: `${rewards.monthsEarned} months, ${rewards.weeksEarned} weeks`,
    verifiedUserIds: [], // Could track which users contributed
    revenueCatTransactionId: result.transactionId,
    awardedAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'awarded',
    expiresAt: result.expiresAt
  });

  // Update stats with redemption timestamp
  await db.collection('referralStats').doc(userId).update({
    'rewardsEarned.lastRewardAt': admin.firestore.FieldValue.serverTimestamp()
  });

  // Send success notification
  await sendReferralNotification(userId, NotificationType.REWARD_REDEEMED, {
    duration: `${rewards.totalDays} days`
  });

  return {
    success: true,
    daysGranted: rewards.totalDays,
    expiresAt: result.expiresAt
  };
});
```

---

### Task 5: Handle Automatic Reward on Verification

**Update verification completion handler**:

```typescript
// In handleVerificationCompletion function
export async function handleVerificationCompletion(userId: string): Promise<void> {
  // ... existing verification logic ...

  // Grant 3 days Premium to referee
  await grantPromotionalEntitlement(userId, 3);

  // Update referrer's available rewards
  const referrerId = verification.referrerId;
  const stats = await getReferralStats(referrerId);

  // Check if referrer hit milestone (every 5 verified)
  if (stats.totalVerified % 5 === 0) {
    // Notify they have rewards to redeem
    await sendReferralNotification(referrerId, NotificationType.MILESTONE_REACHED, {
      reward: '1 month Premium'
    });
  }
}
```

---

### Task 6: Handle Paid Conversion Bonus

**File**: `functions/src/referral/webhooks/revenuecatWebhook.ts`

```typescript
export const handleRevenueCatWebhook = functions.https.onRequest(async (req, res) => {
  // Verify webhook signature (RevenueCat provides this)
  // Parse event type

  if (req.body.event.type === 'INITIAL_PURCHASE') {
    const userId = req.body.event.app_user_id;

    // Check if user was referred
    const verification = await db.collection('referralVerifications').doc(userId).get();

    if (verification.exists && verification.data().verificationStatus === 'verified') {
      const referrerId = verification.data().referrerId;

      // Grant 2 weeks bonus to referrer
      await grantPromotionalEntitlement(referrerId, 14);

      // Update stats
      await db.collection('referralStats').doc(referrerId).update({
        totalPaidConversions: admin.firestore.FieldValue.increment(1)
      });

      // Update verification document
      await db.collection('referralVerifications').doc(userId).update({
        currentTier: 'paid'
      });

      // Send notification
      await sendReferralNotification(referrerId, NotificationType.FRIEND_SUBSCRIBED, {
        friendName: await getUserDisplayName(userId)
      });

      // Log reward
      await db.collection('referralRewards').add({
        referrerId,
        type: 'paid_conversion',
        amount: '2 weeks',
        verifiedUserIds: [userId],
        awardedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'awarded'
      });
    }
  }

  res.status(200).send({ received: true });
});
```

---

### Task 7: Update Flutter Repository with Redemption Method

**File**: `lib/features/referral/data/repositories/referral_repository.dart`

```dart
Future<RedemptionResponse> redeemRewards() async {
  final callable = FirebaseFunctions.instance.httpsCallable('redeemReferralRewards');

  try {
    final result = await callable.call();

    return RedemptionResponse(
      success: true,
      daysGranted: result.data['daysGranted'],
      expiresAt: DateTime.parse(result.data['expiresAt']),
    );
  } catch (e) {
    return RedemptionResponse(
      success: false,
      error: e.message,
    );
  }
}
```

---

### Task 8: Add Redemption UI to Dashboard

**Update**: `lib/features/referral/presentation/screens/referral_dashboard_screen.dart`

Add "Redeem Rewards" button:

```dart
// Show button only if rewards available
if (stats.totalVerified >= 5 || stats.totalPaidConversions > 0) {
  ElevatedButton(
    onPressed: () async {
      final result = await ref.read(referralRepositoryProvider).redeemRewards();

      if (result.success) {
        showSuccessDialog(
          'Rewards Redeemed!',
          'You now have ${result.daysGranted} days of Premium access!'
        );
      } else {
        showErrorDialog(result.error);
      }
    },
    child: Text('Redeem ${calculateDays(stats)} Days Premium'),
  )
}
```

---

### Task 9: Sync with Local Subscription State

**Update subscription checking logic**:

```dart
// After RevenueCat grants promotional entitlement,
// Flutter app needs to refresh subscription status

Future<void> refreshSubscriptionStatus() async {
  final purchaserInfo = await Purchases.getCustomerInfo();
  final isPlus = purchaserInfo.entitlements.active.containsKey('taaafi_plus');

  // Update local state
  await ref.read(subscriptionProvider.notifier).updateStatus(isPlus);
}
```

Call this after redemption.

---

### Task 10: Handle Reward Expiration

**Create scheduled function**:

```typescript
export const checkExpiredRewards = functions.pubsub
  .schedule('0 3 * * *') // Daily at 3 AM
  .onRun(async (context) => {
    // Query referralRewards for expired entitlements
    // Send notification 3 days before expiration
    // Send notification on expiration day
    // Update stats if needed
  });
```

---

### Task 11: Create Fraud Prevention for Rewards

**Before granting rewards**:

```typescript
// Check if user has any blocked referrals
const stats = await getReferralStats(userId);

if (stats.blockedReferrals > 0) {
  // Subtract blocked referrals from total
  const adjustedVerified = stats.totalVerified - stats.blockedReferrals;
  // Recalculate rewards based on adjusted count
}

// Check fraud flags
const recentFlags = await checkRecentFraudFlags(userId);
if (recentFlags.length > 0) {
  throw new Error('Rewards temporarily suspended due to fraud review');
}
```

---

## Testing Criteria

### Integration Tests
1. **Grant promotional entitlement**: Test RevenueCat API call
2. **Reward calculation**: Verify math correct for various scenarios
3. **Redemption flow**: Test end-to-end redemption
4. **Webhook handling**: Test paid conversion bonus
5. **Expiration**: Test rewards expire correctly

### Manual Testing
1. Create 5 verified referrals
2. Verify "Redeem" button appears
3. Click "Redeem", verify success
4. Check RevenueCat dashboard for promotional entitlement
5. Verify app shows Premium access
6. Test paid conversion: Have referred user subscribe
7. Verify referrer gets 2-week bonus
8. Test expiration notification

### Success Criteria
- [ ] RevenueCat integration working
- [ ] Rewards calculated correctly
- [ ] Redemption grants Premium access
- [ ] Paid conversion bonus works
- [ ] Webhook handling functional
- [ ] Expiration tracking works
- [ ] Fraud prevention in place
- [ ] UI shows correct reward amounts
- [ ] Notifications sent on redemption
- [ ] Logs created for audit trail

---

## Security Considerations

1. **RevenueCat API key**: Store securely in Firebase Config
2. **Webhook verification**: Validate RevenueCat signature
3. **Rate limiting**: Prevent reward redemption spam
4. **Fraud checks**: Always validate before granting rewards

---

## Notes for Next Sprint

Sprint 12 begins admin panel implementation. All mobile features complete!

---

**Next Sprint**: `sprint_12_admin_dashboard.md`
