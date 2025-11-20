# Sprint 01: Database Schema & Firestore Security Rules

**Status**: Not Started
**Previous Sprint**: None (First Sprint)
**Next Sprint**: `sprint_02_referral_code_generation.md`
**Estimated Duration**: 4-6 hours

---

## Objectives
Set up the Firestore database schema for the referral program, including collections, document structures, and security rules.

---

## Prerequisites

### Codebase Checks
Before starting, use Firestore MCP to examine:
1. Query existing `users` collection to understand current user document structure
2. Check `firestore.rules` file location and current rule patterns
3. Examine how other collections handle security rules (reference `groups`, `forumPosts`, `communityProfiles`)
4. Check Firebase project configuration in Flutter app

### Required Context
- Firebase project ID
- Current user document fields
- Existing Firestore rules patterns
- Admin role verification method in rules

---

## Tasks

### Task 1: Design Firestore Collections

Create the following collections:

#### 1.1: `referralProgram/config/settings` (Single Document)
```
Purpose: Global referral program configuration
Fields:
  - isEnabled: boolean (default: true)
  - verificationRequirements: map
      - minAccountAgeDays: number (7)
      - minForumPosts: number (3)
      - minInteractions: number (5)
      - minGroupMessages: number (3)
      - minActivitiesStarted: number (1)
  - rewards: map
      - usersPerMonth: number (5)
      - paidConversionBonusWeeks: number (2)
  - fraudThresholds: map
      - lowRisk: number (40)
      - highRisk: number (70)
      - autoBlock: number (71)
  - updatedAt: timestamp
  - updatedBy: string (admin UID)
```

#### 1.2: `referralCodes/{codeId}` (One per User)
```
Purpose: Store unique referral codes for each user
Fields:
  - userId: string (owner's UID)
  - code: string (unique 6-8 character code)
  - createdAt: timestamp
  - isActive: boolean (default: true)
  - totalRedemptions: number (default: 0)
  - lastUsedAt: timestamp?
```

#### 1.3: `referralVerifications/{userId}` (One per Referred User)
```
Purpose: Track verification progress for referred users
Fields:
  - userId: string (referee's UID)
  - referrerId: string (referrer's UID)
  - referralCode: string
  - signupDate: timestamp
  - currentTier: string ('none' | 'verified' | 'paid')

  - checklist: map
      - accountAge7Days: map { completed: boolean, completedAt: timestamp? }
      - forumPosts3: map { completed: boolean, completedAt: timestamp?, current: number }
      - interactions5: map { completed: boolean, completedAt: timestamp?, current: number, uniqueUsers: array }
      - groupJoined: map { completed: boolean, completedAt: timestamp?, groupId: string? }
      - groupMessages3: map { completed: boolean, completedAt: timestamp?, current: number }
      - activityStarted: map { completed: boolean, completedAt: timestamp?, activityId: string? }

  - verificationStatus: string ('pending' | 'verified' | 'blocked')
  - verifiedAt: timestamp?

  - fraudScore: number (0-100)
  - fraudFlags: array (strings)
  - isBlocked: boolean (default: false)
  - blockedReason: string?
  - blockedAt: timestamp?

  - rewardAwarded: boolean (default: false)
  - rewardAwardedAt: timestamp?

  - lastCheckedAt: timestamp
  - updatedAt: timestamp
```

#### 1.4: `referralRewards/{rewardId}` (Log of Rewards)
```
Purpose: Track all reward distributions
Fields:
  - referrerId: string
  - type: string ('verification_milestone' | 'paid_conversion')
  - amount: string (e.g., '1 month', '2 weeks')
  - verifiedUserIds: array (user IDs that contributed to this reward)
  - revenueCatTransactionId: string?
  - awardedAt: timestamp
  - status: string ('pending' | 'awarded' | 'failed')
  - errorMessage: string?
```

#### 1.5: `referralStats/{userId}` (One per User)
```
Purpose: Aggregate stats for referrers
Fields:
  - userId: string
  - totalReferred: number (total signups with code)
  - totalVerified: number (completed verification)
  - totalPaidConversions: number (became paying customers)
  - pendingVerifications: number (in progress)
  - blockedReferrals: number (flagged as fraud)

  - rewardsEarned: map
      - totalMonths: number
      - totalWeeks: number
      - lastRewardAt: timestamp?

  - milestones: array (maps)
      - type: string
      - achievedAt: timestamp
      - reward: string

  - lastUpdatedAt: timestamp
```

---

### Task 2: Update User Document Schema

Add to existing `users/{userId}` collection:
```
New Fields:
  - referralCode: string? (their unique code, indexed)
  - referredBy: string? (UID of referrer, if any)
  - referralSignupDate: timestamp? (when they used a code)
```

**Important**: Do NOT modify existing user documents yet. Just document this change for Sprint 02.

---

### Task 3: Create Firestore Security Rules

Add to `firestore.rules`:

```javascript
// Helper function (add at top if not exists)
function isAdmin() {
  let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid));
  return userDoc.data.role == 'admin';
}

function isAuthenticated() {
  return request.auth != null;
}

// Referral Program Config (Admin only)
match /referralProgram/{document=**} {
  allow read: if isAuthenticated();
  allow write: if isAdmin();
}

// Referral Codes
match /referralCodes/{codeId} {
  // Anyone can read to verify a code exists
  allow read: if isAuthenticated();

  // Only the code owner can update (deactivate)
  allow update: if isAuthenticated() &&
                   request.auth.uid == resource.data.userId &&
                   request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isActive', 'lastUsedAt']);

  // Only Cloud Functions can create/delete
  allow create, delete: if false;
}

// Referral Verifications
match /referralVerifications/{userId} {
  // Users can read their own verification status
  // Referrers can read their referees' status
  allow read: if isAuthenticated() &&
                 (request.auth.uid == userId ||
                  request.auth.uid == resource.data.referrerId);

  // Only Cloud Functions can write
  allow write: if false;
}

// Referral Rewards
match /referralRewards/{rewardId} {
  // Users can read their own rewards
  allow read: if isAuthenticated() &&
                 request.auth.uid == resource.data.referrerId;

  // Only Cloud Functions can write
  allow write: if false;
}

// Referral Stats
match /referralStats/{userId} {
  // Users can read their own stats
  // Admins can read all stats
  allow read: if isAuthenticated() &&
                 (request.auth.uid == userId || isAdmin());

  // Only Cloud Functions can write
  allow write: if false;
}
```

---

### Task 4: Create Firestore Indexes

Add to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "referralCodes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "code", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "referralCodes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "referralVerifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "referrerId", "order": "ASCENDING" },
        { "fieldPath": "verificationStatus", "order": "ASCENDING" },
        { "fieldPath": "signupDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "referralVerifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "verificationStatus", "order": "ASCENDING" },
        { "fieldPath": "fraudScore", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "referralRewards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "referrerId", "order": "ASCENDING" },
        { "fieldPath": "awardedAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

### Task 5: Create Initial Config Document

Create a Cloud Function or script to initialize `referralProgram/config/settings`:

```typescript
// File: functions/src/referral/initializeConfig.ts

import * as admin from 'firebase-admin';

export async function initializeReferralConfig() {
  const db = admin.firestore();

  await db.doc('referralProgram/config/settings').set({
    isEnabled: true,
    verificationRequirements: {
      minAccountAgeDays: 7,
      minForumPosts: 3,
      minInteractions: 5,
      minGroupMessages: 3,
      minActivitiesStarted: 1
    },
    rewards: {
      usersPerMonth: 5,
      paidConversionBonusWeeks: 2
    },
    fraudThresholds: {
      lowRisk: 40,
      highRisk: 70,
      autoBlock: 71
    },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: 'system'
  });
}
```

---

## Testing Criteria

### Verification Steps
1. **Firestore Rules Deploy**: Deploy rules and verify no errors
2. **Index Creation**: Deploy indexes and wait for them to build (check Firebase Console)
3. **Config Document**: Verify `referralProgram/config/settings` exists with correct structure
4. **Rule Testing**: Use Firebase Emulator or Console to test:
   - Authenticated user can read config
   - Non-admin cannot write to config
   - User can read their own referral stats (create test document)
5. **Build Check**: Run Flutter build to ensure no breaking changes

### Success Criteria
- [ ] All collections documented with clear schema
- [ ] Firestore rules deployed successfully
- [ ] Indexes created and building (or built)
- [ ] Config document initialized
- [ ] Rules tested (read/write permissions work as expected)
- [ ] App builds without errors
- [ ] No existing functionality broken

---

## Deployment Checklist

1. Deploy Firestore rules: `firebase deploy --only firestore:rules`
2. Deploy Firestore indexes: `firebase deploy --only firestore:indexes`
3. Run config initialization function (or manually create document)
4. Verify in Firebase Console that collections are ready
5. Test read permissions with a test user account

---

## Notes for Next Sprint

Document the following for Sprint 02:
- Referral code format chosen (e.g., 6 characters, alphanumeric)
- Any edge cases discovered during rule testing
- Current user document structure for reference

---

## Rollback Plan

If issues arise:
1. Previous Firestore rules are versioned in Firebase Console (can rollback)
2. New collections don't affect existing functionality
3. Indexes can be deleted from Firebase Console if needed
4. Config document can be deleted without side effects

---

**Next Sprint**: `sprint_02_referral_code_generation.md`
