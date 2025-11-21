# Sprint 05: Verification Checklist Tracking (Firestore Triggers)

**Status**: ✅ Completed
**Previous Sprint**: `sprint_04_checklist_functions_setup.md`
**Next Sprint**: `sprint_06_fraud_detection.md`
**Estimated Duration**: 8-10 hours

---

## Objectives
Implement Firestore triggers that automatically track user activity and update verification checklist progress. Track forum posts, comments, interactions, group activity, and recovery activities.

---

## Prerequisites

### Verify Sprint 04 Completion
- [ ] Helper modules created
- [ ] TypeScript types defined
- [ ] Base functions deployed

### Codebase Checks
Use Firestore MCP to examine:
1. Structure of `forumPosts` collection
2. Structure of `comments` collection
3. Structure of `interactions` collection
4. Structure of `groups/{groupId}/group_messages` collection
5. Structure of `users/{userId}/ongoing_activities` subcollection
6. Structure of `group_memberships` collection

---

## Tasks

### Task 1: Forum Post Tracking Trigger

**File**: `functions/src/referral/triggers/forumPostTrigger.ts`

```typescript
export const onForumPostCreated = functions.firestore
  .document('forumPosts/{postId}')
  .onCreate(async (snap, context) => {
    // Get post author's Community Profile ID
    // Convert CP ID to user UID
    // Check if user has pending verification
    // Increment forumPosts3.current
    // If current >= 3, mark completed
    // Update verification document
    // Check if verification complete
    // Update fraud score
  });
```

**Key logic**:
- Convert `authorCPId` to user UID (query `communityProfiles` collection)
- Increment `checklist.forumPosts3.current`
- When `current >= 3`, set `completed: true` and `completedAt: timestamp`
- Call `checkVerificationCompletion()` after update

---

### Task 2: Comment Tracking Trigger

**File**: `functions/src/referral/triggers/commentTrigger.ts`

```typescript
export const onCommentCreated = functions.firestore
  .document('comments/{commentId}')
  .onCreate(async (snap, context) => {
    // Get comment author's CP ID
    // Convert to user UID
    // Check verification status
    // Increment interactions5.current
    // Add commenter to uniqueUsers array (if not exists)
    // If current >= 5, mark completed
    // Update verification document
    // Check completion
  });
```

---

### Task 3: Interaction (Like) Tracking Trigger

**File**: `functions/src/referral/triggers/interactionTrigger.ts`

```typescript
export const onInteractionCreated = functions.firestore
  .document('interactions/{interactionId}')
  .onCreate(async (snap, context) => {
    // Get interaction user's CP ID
    // Convert to user UID
    // Check verification status
    // Increment interactions5.current
    // Add target user to uniqueUsers array
    // If current >= 5, mark completed
    // Update verification document
  });
```

**Note**: Combine comments + interactions to reach 5 total interactions.

---

### Task 4: Group Membership Tracking Trigger

**File**: `functions/src/referral/triggers/groupMembershipTrigger.ts`

```typescript
export const onGroupMembershipCreated = functions.firestore
  .document('groups/{groupId}/group_memberships/{membershipId}')
  .onCreate(async (snap, context) => {
    // Get member's CP ID
    // Convert to user UID
    // Check verification status
    // Mark groupJoined as completed
    // Store groupId in checklist
    // Update verification document
  });
```

---

### Task 5: Group Message Tracking Trigger

**File**: `functions/src/referral/triggers/groupMessageTrigger.ts`

```typescript
export const onGroupMessageCreated = functions.firestore
  .document('groups/{groupId}/group_messages/{messageId}')
  .onCreate(async (snap, context) => {
    // Get sender's CP ID
    // Convert to user UID
    // Check verification status
    // Verify this is their joined group (from groupJoined.groupId)
    // Increment groupMessages3.current
    // If current >= 3, mark completed
    // Update verification document
    // Check fraud (rapid messaging)
  });
```

---

### Task 6: Activity Subscription Tracking Trigger

**File**: `functions/src/referral/triggers/activityTrigger.ts`

```typescript
export const onActivitySubscribed = functions.firestore
  .document('users/{userId}/ongoing_activities/{activityId}')
  .onCreate(async (snap, context) => {
    // Get userId from path
    // Check verification status
    // Mark activityStarted as completed
    // Store activityId in checklist
    // Update verification document
    // Check completion
  });
```

---

### Task 7: Verification Completion Handler

**File**: `functions/src/referral/handlers/verificationHandler.ts`

```typescript
export async function handleVerificationCompletion(userId: string): Promise<void> {
  // Get verification document
  // Check all checklist items completed
  // Check account age >= 7 days
  // Calculate final fraud score
  // If fraud score > 70: block user, notify admin
  // If fraud score 40-70: flag for review
  // If fraud score < 40: mark as verified
  // Update referrer stats
  // Award rewards (will be implemented in Sprint 11)
  // Send notifications (will be implemented in Sprint 10)
}
```

This is called by each trigger after updating checklist.

---

### Task 8: Helper - Convert CP ID to User UID

**File**: Add to `functions/src/referral/helpers/userHelper.ts`

```typescript
export async function getUserIdFromCPId(cpId: string): Promise<string | null> {
  const cpDoc = await db.collection('communityProfiles').doc(cpId).get();
  if (!cpDoc.exists) return null;
  return cpDoc.data()?.userUID || null;
}

// Cache for performance (optional)
const cpIdCache = new Map<string, string>();

export async function getUserIdFromCPIdCached(cpId: string): Promise<string | null> {
  if (cpIdCache.has(cpId)) return cpIdCache.get(cpId)!;
  const userId = await getUserIdFromCPId(cpId);
  if (userId) cpIdCache.set(cpId, userId);
  return userId;
}
```

---

### Task 9: Prevent Double-Counting

Add check in each trigger:
```typescript
// Before incrementing, check if this specific action was already counted
// Use subcollection or tracking document to prevent duplicates
// Example: referralVerifications/{userId}/trackedActions/{actionId}
```

Create helper:
```typescript
export async function isActionAlreadyCounted(
  userId: string,
  actionType: string,
  actionId: string
): Promise<boolean> {
  const doc = await db
    .collection('referralVerifications')
    .doc(userId)
    .collection('trackedActions')
    .doc(actionId)
    .get();
  return doc.exists;
}

export async function markActionAsCounted(
  userId: string,
  actionType: string,
  actionId: string
): Promise<void> {
  await db
    .collection('referralVerifications')
    .doc(userId)
    .collection('trackedActions')
    .doc(actionId)
    .set({
      actionType,
      countedAt: admin.firestore.FieldValue.serverTimestamp()
    });
}
```

---

## Testing Criteria

### Integration Tests
1. **Forum Post**: Create post as referred user, verify checklist updated
2. **Comments**: Create 5 comments, verify interactions tracked
3. **Likes**: Like 5 posts, verify interactions tracked
4. **Group Join**: Join group, verify checklist updated
5. **Group Messages**: Send 3 messages, verify checklist updated
6. **Activity**: Subscribe to activity, verify checklist updated
7. **Completion**: Complete all items, verify verification status changes

### Manual Testing Flow
1. Create two accounts: Referrer (A) and Referee (B)
2. B uses A's referral code
3. B completes each checklist item:
   - Post 3 forum posts → check Firestore after each
   - Like/comment 5 times → check progress
   - Join group → check immediately
   - Send 3 group messages → check after each
   - Subscribe to activity → check immediately
4. Wait 7 days OR manually set account age
5. Verify B's verification status changes to "verified"
6. Verify A's stats updated (totalVerified++)

### Success Criteria
- [ ] All triggers deployed successfully
- [ ] Checklist items update in real-time
- [ ] No duplicate counting
- [ ] Completion handler triggers when all items done
- [ ] Fraud score calculated
- [ ] Stats updated correctly
- [ ] App remains stable and performant

---

## Deployment Checklist

1. Deploy all triggers: `firebase deploy --only functions`
2. Monitor Cloud Functions logs for errors
3. Test each trigger individually in staging
4. Verify Firestore document updates
5. Check performance (function execution time)

---

## Performance Considerations

- **Trigger execution cost**: Monitor Firebase billing
- **Read/Write operations**: Optimize batch updates
- **Caching**: Use CP ID → User ID cache
- **Indexes**: Ensure all queries have proper indexes

---

## Edge Cases

1. **User deletes post/comment**: Don't decrement (once counted, stays counted)
2. **User leaves group**: Don't affect checklist (they already completed it)
3. **Concurrent actions**: Use Firestore transactions to prevent race conditions
4. **Missing CP profile**: Handle gracefully, log error

---

## Notes for Next Sprint

Sprint 06 will implement comprehensive fraud detection. Track any suspicious patterns noticed during testing.

Document:
- Trigger execution times
- Any performance bottlenecks
- False positive fraud detections

---

**Next Sprint**: `sprint_06_fraud_detection.md`
