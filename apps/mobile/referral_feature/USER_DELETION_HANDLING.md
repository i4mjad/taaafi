# Referral System - User Deletion Handling

## Overview

This document describes how the referral system handles user account deletions to ensure data integrity, accurate statistics, and proper notifications.

---

## Problem Statement

When a user who participated in the referral program (either as a referrer or referee) deletes their account, we need to:

1. ✅ **Notify affected parties** - Let referrers know if their referred users delete accounts
2. ✅ **Update statistics accurately** - Ensure referrer stats don't count deleted users
3. ✅ **Preserve audit trail** - Keep data for audit purposes (don't delete it)
4. ✅ **Prevent reward exploitation** - Ensure deleted users don't count toward rewards

---

## Implementation

### File Structure

```
functions/src/referral/handlers/
  └── userDeletionHandler.ts          # Main deletion handler

functions/src/
  └── index.ts                        # Integration with deleteUserAccount
```

### When a REFEREE (referred user) deletes their account

**What happens:**

1. **Verification Status Updated**
   - Status changed from `pending`/`verified` → `deleted`
   - `deletedAt` timestamp added
   - `deletedReason` set to "User account deleted"
   - Document preserved (not deleted)

2. **Referrer Stats Updated**
   - `totalReferred` decremented by 1
   - `totalVerified` decremented by 1 (if user was verified)
   - `pendingVerifications` decremented by 1 (if user was pending)

3. **Referral Code Updated**
   - `totalRedemptions` decremented by 1
   - Code remains active for other users

4. **Referrer Notified**
   - Push notification sent to referrer
   - Message explains that a referred user deleted their account
   - Includes whether the user was verified or not

5. **Audit Log Created**
   - Entry added to `referralFraudLogs` collection
   - Tracks: userId, referrerId, verification status, fraud score
   - Action type: `user_deleted`

**Example Notification:**

```
English: "One of your verified referrals has deleted their account. Your stats have been updated."
Arabic: "أحد المستخدمين الذين تمت إحالتهم قد حذف حسابه. تم تحديث إحصائياتك."
```

---

### When a REFERRER deletes their account

**What happens:**

1. **Referral Code Deactivated**
   - `isActive` set to false
   - `deactivatedAt` timestamp added
   - `deactivatedReason` set to "User account deleted"
   - Code can no longer be used by new users

2. **Referral Stats Marked as Deleted**
   - `isDeleted` set to true
   - `deletedAt` timestamp added
   - Stats preserved for audit purposes

3. **All Verifications Updated**
   - `referrerDeleted` flag set to true
   - `referrerDeletedAt` timestamp added
   - Verifications preserved but marked

4. **All Rewards Updated**
   - `referrerDeleted` flag set to true
   - `referrerDeletedAt` timestamp added
   - Rewards preserved but marked

---

## Database Schema Updates

### `referralVerifications/{userId}`

**New Fields:**
```typescript
{
  verificationStatus: 'pending' | 'verified' | 'blocked' | 'deleted',  // Added 'deleted'
  deletedAt?: Timestamp,           // When referee deleted their account
  deletedReason?: string,          // Reason for deletion
  referrerDeleted?: boolean,       // True if referrer deleted their account
  referrerDeletedAt?: Timestamp    // When referrer deleted their account
}
```

### `referralStats/{userId}`

**New Fields:**
```typescript
{
  isDeleted?: boolean,    // True if this referrer deleted their account
  deletedAt?: Timestamp   // When referrer deleted their account
}
```

### `referralCodes/{codeId}`

**New Fields:**
```typescript
{
  deactivatedAt?: Timestamp,     // When code was deactivated
  deactivatedReason?: string     // Reason (e.g., "User account deleted")
}
```

### `referralRewards/{rewardId}`

**New Fields:**
```typescript
{
  referrerDeleted?: boolean,      // True if referrer deleted their account
  referrerDeletedAt?: Timestamp   // When referrer deleted their account
}
```

---

## Integration with User Account Deletion

The referral deletion handler is integrated into the main `deleteUserAccount` function:

```typescript
// functions/src/index.ts

export const deleteUserAccount = onCall(async (request) => {
  // ... authentication and setup ...
  
  try {
    // 1. Delete Community Data
    await deleteCommunityData(db, userId, deletionSummary);
    
    // 2. Delete Vault Data
    await deleteVaultData(db, userId, deletionSummary);
    
    // 3. Handle Referral Data ⭐ NEW
    await handleReferralDataOnDeletion(db, userId, deletionSummary);
    
    // 4. Delete User Profile
    await deleteUserProfile(db, userId, deletionSummary);
    
    // 5. Delete Authentication Records
    await deleteAuthenticationData(db, userId, deletionSummary);
    
    // 6. Create Audit Record
    await createDeletionAuditRecord(db, deletionSummary);
  } catch (error) {
    // Error handling...
  }
});
```

---

## Error Handling

### Non-Blocking Errors

If referral cleanup fails, the account deletion continues. Errors are logged but don't block the deletion:

```typescript
try {
  await handleReferralDataOnDeletion(db, userId, deletionSummary);
} catch (error) {
  console.error('❌ Error handling referral data:', error);
  summary.errors.push(`Referral cleanup failed: ${error.message}`);
  // Continue with deletion - don't throw
}
```

### Notification Failures

If sending notification to referrer fails:
- Error is logged
- Error added to result.errors array
- Process continues (referrer missing notification is not critical)

---

## Testing Scenarios

### Scenario 1: Verified Referee Deletes Account

**Given:**
- User A (referrer) has referred User B
- User B completed verification (status: 'verified')
- User A's stats: totalReferred=1, totalVerified=1

**When:**
- User B deletes their account

**Then:**
- User B's verification status → 'deleted'
- User A's stats: totalReferred=0, totalVerified=0
- User A receives notification
- Audit log created

### Scenario 2: Pending Referee Deletes Account

**Given:**
- User A (referrer) has referred User C
- User C is still pending verification (status: 'pending')
- User A's stats: totalReferred=1, pendingVerifications=1

**When:**
- User C deletes their account

**Then:**
- User C's verification status → 'deleted'
- User A's stats: totalReferred=0, pendingVerifications=0
- User A receives notification
- Audit log created

### Scenario 3: Referrer with Multiple Referrals Deletes Account

**Given:**
- User D (referrer) has referred 5 users
- User D has an active referral code

**When:**
- User D deletes their account

**Then:**
- User D's referral code is deactivated
- User D's stats marked as deleted (but preserved)
- All 5 verification documents marked with referrerDeleted=true
- Any rewards marked with referrerDeleted=true
- Referred users NOT notified (their verification still exists)

---

## Audit Trail

All deletion events are logged to `referralFraudLogs`:

```typescript
{
  userId: "deleted-user-id",
  action: "user_deleted",
  referrerId: "referrer-user-id",
  wasVerified: true,
  rewardAwarded: false,
  reason: "User account deleted",
  performedBy: "system",
  timestamp: Timestamp,
  details: {
    verificationStatus: "verified",
    fraudScore: 15,
    checklist: { /* ... */ }
  }
}
```

---

## Performance Considerations

### Execution Time

- Average execution time: ~2-5 seconds
- Operations performed: 4-6 Firestore operations
- Includes: reads, updates, notification sending

### Firestore Operations

**For Referee Deletion:**
- 1 read (verification document)
- 1 update (verification status)
- 1-2 reads/updates (referrer stats)
- 1 query + update (referral code)
- 1 write (audit log)
- 1 notification send

**For Referrer Deletion:**
- 1 query + update (referral code)
- 1 read + update (referral stats)
- N queries + updates (all verifications)
- M queries + updates (all rewards)

---

## Localization

Notifications are sent in the referrer's preferred language:

**English:**
- Title: "Referral Update"
- Message: "One of your verified referrals has deleted their account. Your stats have been updated."

**Arabic:**
- Title: "تحديث في برنامج الإحالة"
- Message: "أحد المستخدمين الذين تمت إحالتهم قد حذف حسابه. تم تحديث إحصائياتك."

---

## Security Considerations

### Access Control

- Only the authenticated user can delete their own account
- Referral handler runs with system privileges (Cloud Function)
- No client-side access to referral deletion logic

### Data Preservation

- **Never delete** referral data, only mark as deleted
- Preserves audit trail for fraud investigation
- Allows for potential account restoration scenarios

### Fraud Prevention

- Deleted users don't count toward rewards
- Prevents "sign up → get verified → delete → repeat" exploits
- Audit logs track all deletion events

---

## Monitoring

### Logs to Watch

```
✅ Marked verification as deleted for user {userId}
✅ Updated referrer stats for {referrerId}
✅ Notification sent to referrer {referrerId}
✅ Audit log created for deleted user {userId}
⚠️ Failed to send notification to referrer: {error}
❌ Error handling referral user deletion: {error}
```

### Metrics to Track

- Number of deleted users per month
- Referrer notification success rate
- Average verification status before deletion
- Time between signup and deletion (fraud indicator)

---

## Future Enhancements

### Possible Improvements

1. **Batch Processing**: Handle large-scale deletions more efficiently
2. **Undo Window**: Allow 30-day grace period before stats updated
3. **Detailed Notifications**: Include referral progress details in notification
4. **Analytics Dashboard**: Track deletion patterns for fraud detection
5. **Automated Fraud Checks**: Flag suspicious deletion patterns

---

## Deployment Checklist

- [x] Create userDeletionHandler.ts
- [x] Integrate with deleteUserAccount function
- [x] Update database schema documentation
- [x] Add to Sprint 19 security audit checklist
- [ ] Deploy Cloud Functions
- [ ] Test referee deletion scenario
- [ ] Test referrer deletion scenario
- [ ] Verify notifications sent correctly
- [ ] Monitor logs for errors
- [ ] Verify stats updated correctly

---

## Related Documentation

- `sprint_01_database_schema.md` - Database schema updates
- `sprint_19_security_audit.md` - Security and compliance
- `functions/src/referral/handlers/userDeletionHandler.ts` - Implementation
- `functions/src/index.ts` - Integration point

---

**Last Updated**: 2025-11-22  
**Status**: ✅ Implemented  
**Version**: 1.0

