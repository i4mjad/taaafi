# Sprint 06: Fraud Detection System

**Status**: Not Started
**Previous Sprint**: `sprint_05_checklist_tracking.md`
**Next Sprint**: `sprint_07_referral_dashboard_ui.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Implement comprehensive fraud detection algorithms that automatically identify and flag suspicious referral activity patterns.

---

## Prerequisites

### Verify Sprint 05 Completion
- [ ] All checklist tracking triggers working
- [ ] Verification documents updating correctly

### Codebase Checks
1. Check if device IDs are stored in user documents
2. Verify `devicesIds` field structure
3. Look for IP address logging (if available)

---

## Tasks

### Task 1: Implement Fraud Detection Checks

**File**: `functions/src/referral/fraud/fraudChecks.ts`

Implement individual fraud checks:

```typescript
// Check 1: Device ID Overlap
export async function checkDeviceOverlap(
  refereeId: string,
  referrerId: string
): Promise<{ score: number; flag: string | null }> {
  // Get both users' device IDs
  // Check for any overlap
  // Return score: 50 if overlap, 0 if no overlap
}

// Check 2: Rapid Posting Pattern
export async function checkPostingPattern(
  userId: string
): Promise<{ score: number; flag: string | null }> {
  // Query user's forum posts
  // Calculate average time between posts
  // If < 2 minutes average: return score 25
}

// Check 3: Interaction Concentration
export async function checkInteractionConcentration(
  userId: string
): Promise<{ score: number; flag: string | null }> {
  // Get verification doc with uniqueUsers array
  // If interactions >= 5 but uniqueUsers < 3: return score 40
}

// Check 4: Rapid Group Messaging
export async function checkGroupMessagingPattern(
  userId: string
): Promise<{ score: number; flag: string | null }> {
  // Get user's group messages
  // Check if 3+ messages sent within 5 minutes
  // Return score 30 if rapid
}

// Check 5: Account Age vs Activity Burst
export async function checkActivityBurst(
  userId: string
): Promise<{ score: number; flag: string | null }> {
  // Get account age
  // Get checklist completion count
  // If account < 24 hours and completedItems > 4: return score 30
}

// Check 6: Content Quality
export async function checkContentQuality(
  userId: string
): Promise<{ score: number; flag: string | null }> {
  // Get user's forum posts
  // Calculate average word count
  // If < 10 words average: return score 20
}

// Check 7: Email Pattern
export async function checkEmailPattern(
  userId: string
): Promise<{ score: number; flag: string | null }> {
  // Get user email
  // Check for Gmail alias pattern (user+1@gmail.com)
  // Return score 10 if pattern detected
}
```

---

### Task 2: Aggregate Fraud Score Calculator

**File**: `functions/src/referral/fraud/fraudScoreCalculator.ts`

```typescript
export async function calculateCompleteFraudScore(userId: string): Promise<{
  totalScore: number;
  flags: string[];
  checks: FraudCheckResult[];
}> {
  // Run all fraud checks
  // Sum scores
  // Collect flags
  // Cap total at 100
  // Return detailed results
}

export interface FraudCheckResult {
  checkName: string;
  score: number;
  flag: string | null;
  details?: any;
}
```

---

### Task 3: Update Fraud Score After Each Activity

Add to existing triggers (from Sprint 05):

```typescript
// At end of each trigger function, update fraud score
await updateFraudScore(userId);
```

Implement updateFraudScore:
```typescript
export async function updateFraudScore(userId: string): Promise<void> {
  const result = await calculateCompleteFraudScore(userId);

  await db.collection('referralVerifications').doc(userId).update({
    fraudScore: result.totalScore,
    fraudFlags: result.flags,
    lastCheckedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // If score > 70, auto-block
  if (result.totalScore >= 71) {
    await blockUserForFraud(userId, 'Automatic block: High fraud score', result.totalScore);
  }

  // If score 40-70, flag for review
  if (result.totalScore >= 40 && result.totalScore < 71) {
    await flagUserForReview(userId, result.totalScore);
  }
}
```

---

### Task 4: Auto-Block High Fraud Users

**File**: `functions/src/referral/fraud/fraudActions.ts`

```typescript
export async function blockUserForFraud(
  userId: string,
  reason: string,
  score: number
): Promise<void> {
  // Update verification document
  await db.collection('referralVerifications').doc(userId).update({
    isBlocked: true,
    blockedReason: reason,
    blockedAt: admin.firestore.FieldValue.serverTimestamp(),
    verificationStatus: 'blocked'
  });

  // Update referrer stats (increment blockedReferrals)
  const verification = await getVerificationDoc(userId);
  if (verification?.referrerId) {
    await db.collection('referralStats').doc(verification.referrerId).update({
      blockedReferrals: admin.firestore.FieldValue.increment(1)
    });
  }

  // Send notification to admin
  await notifyAdminOfFraudBlock(userId, reason, score);

  // Log to admin audit collection
  await logFraudBlock(userId, reason, score);
}

export async function flagUserForReview(
  userId: string,
  score: number
): Promise<void> {
  // Add 'needs_manual_review' flag
  await db.collection('referralVerifications').doc(userId).update({
    fraudFlags: admin.firestore.FieldValue.arrayUnion('needs_manual_review')
  });

  // Notify admin
  await notifyAdminOfFraudFlag(userId, score);
}
```

---

### Task 5: Create Admin Callable Functions

**File**: `functions/src/referral/admin/fraudManagement.ts`

```typescript
// Admin can manually approve flagged user
export const approveReferralVerification = functions.https.onCall(async (data, context) => {
  // Verify admin role
  // Remove fraud flags
  // Mark as verified
  // Award rewards
});

// Admin can manually block user
export const blockReferralUser = functions.https.onCall(async (data, context) => {
  // Verify admin role
  // Block user with custom reason
  // Update stats
});

// Admin can get fraud details
export const getFraudDetails = functions.https.onCall(async (data, context) => {
  // Verify admin role
  // Run all fraud checks
  // Return detailed breakdown
});
```

---

### Task 6: Create Fraud Audit Log Collection

Create collection: `referralFraudLogs/{logId}`

```typescript
interface FraudLog {
  userId: string;
  action: 'auto_block' | 'flagged' | 'manual_block' | 'approved';
  fraudScore: number;
  fraudFlags: string[];
  reason: string;
  performedBy: string; // 'system' or admin UID
  timestamp: FirebaseFirestore.Timestamp;
  details: object;
}
```

---

### Task 7: Advanced Pattern Detection

**File**: `functions/src/referral/fraud/patternDetection.ts`

```typescript
// Detect if multiple referred users show identical patterns
export async function detectCoordinatedFraud(referrerId: string): Promise<boolean> {
  // Get all referrer's referrals
  // Check for suspicious similarities:
  //   - Same device IDs
  //   - Sequential email addresses
  //   - Identical posting times
  //   - Similar content
  // Return true if coordinated fraud suspected
}

// Check if user's activity matches a known fraud template
export async function matchesFraudTemplate(userId: string): Promise<boolean> {
  // Compare activity pattern to known fraud patterns
  // Examples:
  //   - Exactly 3 posts, 5 interactions, 3 messages in 1 hour
  //   - Posts contain minimum required words only
  //   - No variation in activity times
}
```

---

## Testing Criteria

### Unit Tests
1. Test each fraud check function with mock data
2. Verify score calculations are correct
3. Test threshold logic (40, 70, 71)

### Integration Tests
1. **Legitimate User**: Complete checklist normally, verify low fraud score
2. **Same Device**: Use same device for referrer and referee, verify 50+ score
3. **Rapid Activity**: Complete checklist in 1 hour, verify high score
4. **Spam Posts**: Create minimum-quality posts, verify score increases
5. **Auto-Block**: Trigger score > 70, verify user blocked
6. **Manual Review**: Trigger score 40-70, verify flagged

### Manual Testing
1. Create intentionally fraudulent referral
2. Monitor fraud score updates in real-time
3. Verify auto-block triggers correctly
4. Test admin approval/block functions

### Success Criteria
- [ ] All fraud checks implemented
- [ ] Fraud score updates automatically
- [ ] Auto-block works for score > 70
- [ ] Manual review flags for score 40-70
- [ ] Admin functions work correctly
- [ ] Legitimate users not flagged
- [ ] Fraud logs created properly

---

## Deployment Checklist

1. Deploy functions: `firebase deploy --only functions`
2. Test fraud detection in staging with fake accounts
3. Verify admin functions require admin role
4. Monitor fraud logs collection
5. Adjust thresholds if needed (config document)

---

## Tuning Fraud Detection

After deployment, monitor and adjust:
- **False positives**: Lower thresholds if legitimate users flagged
- **False negatives**: Increase thresholds if fraud slips through
- **New patterns**: Add new checks as fraud patterns emerge

Document baseline metrics:
- Average fraud score for legitimate users
- Percentage of users flagged for review
- Percentage auto-blocked

---

## Notes for Next Sprint

Sprint 07 will create the user-facing referral dashboard. Fraud system runs silently in background.

---

**Next Sprint**: `sprint_07_referral_dashboard_ui.md`
