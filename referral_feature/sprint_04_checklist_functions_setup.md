# Sprint 04: Verification Checklist Cloud Functions (Setup)

**Status**: Not Started
**Previous Sprint**: `sprint_03_referral_code_input.md`
**Next Sprint**: `sprint_05_checklist_tracking.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Set up the infrastructure for tracking verification checklist progress. Create base Cloud Functions and helper utilities that will be extended in Sprint 05.

---

## Prerequisites

### Verify Sprint 03 Completion
- [ ] Referral code redemption working
- [ ] `referralVerifications` documents created on redemption
- [ ] User linking functional

### Codebase Checks
1. Examine existing Cloud Functions structure
2. Check how other Firestore triggers are organized
3. Look for shared utilities/helpers
4. Understand current user activity tracking patterns

---

## Tasks

### Task 1: Create Verification Checklist Helper Module

**File**: `functions/src/referral/helpers/checklistHelper.ts`

Core functions:
```typescript
// Check if user meets verification criteria
export async function checkVerificationCompletion(userId: string): Promise<boolean>

// Update specific checklist item
export async function updateChecklistItem(
  userId: string,
  itemKey: string,
  data: Partial<ChecklistItem>
): Promise<void>

// Calculate completion percentage
export async function getChecklistProgress(userId: string): Promise<number>

// Check if account age requirement met
export async function checkAccountAge(userId: string, minDays: number): Promise<boolean>
```

---

### Task 2: Create Fraud Detection Helper Module

**File**: `functions/src/referral/helpers/fraudDetection.ts`

Initial fraud checks:
```typescript
// Calculate fraud score for a user
export async function calculateFraudScore(userId: string): Promise<number>

// Check if devices match between referrer and referee
export async function checkDeviceOverlap(userId: string, referrerId: string): Promise<boolean>

// Check posting patterns for suspicious activity
export async function checkPostingPattern(userId: string): Promise<number>

// Check interaction concentration (are they only interacting with one user?)
export async function checkInteractionConcentration(userId: string): Promise<number>

// Update fraud score in verification document
export async function updateFraudScore(userId: string, score: number): Promise<void>

// Add fraud flag
export async function addFraudFlag(userId: string, flag: string): Promise<void>
```

---

### Task 3: Create Verification Status Helper Module

**File**: `functions/src/referral/helpers/verificationStatus.ts`

```typescript
// Get verification requirements from config
export async function getVerificationRequirements(): Promise<VerificationRequirements>

// Check if all checklist items completed
export async function isChecklistComplete(userId: string): Promise<boolean>

// Mark user as verified
export async function markUserAsVerified(userId: string): Promise<void>

// Block user for fraud
export async function blockUserForFraud(
  userId: string,
  reason: string,
  score: number
): Promise<void>

// Get verification document
export async function getVerificationDoc(userId: string): Promise<ReferralVerification | null>
```

---

### Task 4: Create Stats Update Helper Module

**File**: `functions/src/referral/helpers/statsHelper.ts`

```typescript
// Increment referrer's pending verifications
export async function incrementPendingVerifications(referrerId: string): Promise<void>

// Move from pending to verified
export async function movePendingToVerified(referrerId: string): Promise<void>

// Increment blocked referrals count
export async function incrementBlockedReferrals(referrerId: string): Promise<void>

// Update last activity timestamp
export async function updateStatsTimestamp(userId: string): Promise<void>
```

---

### Task 5: Create TypeScript Interfaces

**File**: `functions/src/referral/types/referral.types.ts`

Define all types:
```typescript
export interface ChecklistItem {
  completed: boolean;
  completedAt: FirebaseFirestore.Timestamp | null;
  current?: number;
  groupId?: string;
  activityId?: string;
  uniqueUsers?: string[];
  categories?: string[];
}

export interface ReferralVerification {
  userId: string;
  referrerId: string;
  referralCode: string;
  signupDate: FirebaseFirestore.Timestamp;
  currentTier: 'none' | 'verified' | 'paid';
  checklist: {
    accountAge7Days: ChecklistItem;
    forumPosts3: ChecklistItem;
    interactions5: ChecklistItem;
    groupJoined: ChecklistItem;
    groupMessages3: ChecklistItem;
    activityStarted: ChecklistItem;
  };
  verificationStatus: 'pending' | 'verified' | 'blocked';
  verifiedAt: FirebaseFirestore.Timestamp | null;
  fraudScore: number;
  fraudFlags: string[];
  isBlocked: boolean;
  blockedReason: string | null;
  blockedAt: FirebaseFirestore.Timestamp | null;
  rewardAwarded: boolean;
  rewardAwardedAt: FirebaseFirestore.Timestamp | null;
  lastCheckedAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface VerificationRequirements {
  minAccountAgeDays: number;
  minForumPosts: number;
  minInteractions: number;
  minGroupMessages: number;
  minActivitiesStarted: number;
}

export interface FraudThresholds {
  lowRisk: number;
  highRisk: number;
  autoBlock: number;
}
```

---

### Task 6: Create Scheduled Function - Check Account Age

**File**: `functions/src/referral/scheduledChecks.ts`

```typescript
// Runs daily at 2 AM
export const checkPendingVerificationAges = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    // Query all pending verifications
    // Check if account age >= 7 days
    // Update checklist item if met
    // Check if verification complete
    // Log results
  });
```

This ensures account age requirement gets checked even if user is inactive.

---

### Task 7: Create Test Helper Functions

**File**: `functions/src/referral/helpers/testHelpers.ts`

For testing and debugging:
```typescript
// Get full verification status for debugging
export async function getVerificationDebugInfo(userId: string): Promise<object>

// Manually trigger verification check (admin only)
export async function manualVerificationCheck(userId: string): Promise<object>

// Reset verification for testing (admin only, staging only)
export async function resetVerification(userId: string): Promise<void>
```

---

### Task 8: Update Existing Redemption Function

**File**: Update `functions/src/referral/redeemReferralCode.ts`

After creating verification document, initialize checklist with defaults:
```typescript
const verification: ReferralVerification = {
  userId: user.uid,
  referrerId: referrerDoc.data().userId,
  referralCode: code,
  signupDate: admin.firestore.FieldValue.serverTimestamp(),
  currentTier: 'none',
  checklist: {
    accountAge7Days: { completed: false, completedAt: null },
    forumPosts3: { completed: false, completedAt: null, current: 0 },
    interactions5: { completed: false, completedAt: null, current: 0, uniqueUsers: [] },
    groupJoined: { completed: false, completedAt: null },
    groupMessages3: { completed: false, completedAt: null, current: 0 },
    activityStarted: { completed: false, completedAt: null }
  },
  verificationStatus: 'pending',
  verifiedAt: null,
  fraudScore: 0,
  fraudFlags: [],
  isBlocked: false,
  blockedReason: null,
  blockedAt: null,
  rewardAwarded: false,
  rewardAwardedAt: null,
  lastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
};

await db.collection('referralVerifications').doc(user.uid).set(verification);
```

---

## Testing Criteria

### Unit Tests
1. **Checklist Helper**: Test checklist item updates
2. **Fraud Detection**: Test device overlap detection
3. **Verification Status**: Test completion check logic
4. **Stats Helper**: Test increment operations

### Integration Tests
1. **Helper Functions**: Test with real Firestore (emulator)
2. **Scheduled Function**: Test with Firestore time travel
3. **Account Age Check**: Verify 7-day calculation

### Manual Testing
1. Create verification document manually
2. Call helper functions via test script
3. Verify document updates correctly
4. Test fraud score calculation with mock data

### Success Criteria
- [ ] All helper modules created and organized
- [ ] TypeScript types defined
- [ ] Scheduled function deployed
- [ ] Redemption function updated with full checklist init
- [ ] Unit tests pass
- [ ] Functions deploy successfully
- [ ] No TypeScript compilation errors

---

## Deployment Checklist

1. Deploy all functions: `firebase deploy --only functions`
2. Verify scheduled function registered (check Firebase Console)
3. Test helper functions using Firebase Emulator
4. Run integration tests in staging environment

---

## Notes for Next Sprint

Sprint 05 will add triggers for each checklist item (forum posts, comments, group messages, etc.). This sprint sets up the foundation.

Document:
- Helper function performance
- Any Firestore query optimizations needed
- TypeScript type issues encountered

---

**Next Sprint**: `sprint_05_checklist_tracking.md`
