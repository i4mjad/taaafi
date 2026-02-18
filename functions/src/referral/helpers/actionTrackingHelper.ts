// functions/src/referral/helpers/actionTrackingHelper.ts
import * as admin from 'firebase-admin';

/**
 * Checks if a specific action has already been counted for verification tracking.
 * Uses a subcollection to prevent duplicate counting if triggers re-run.
 * 
 * @param userId - The user's UID
 * @param actionType - Type of action (e.g., 'forumPost', 'comment', 'like', 'groupMessage')
 * @param actionId - Unique ID of the action (document ID from Firestore)
 * @returns true if action was already counted, false otherwise
 */
export async function isActionAlreadyCounted(
  userId: string,
  actionType: string,
  actionId: string
): Promise<boolean> {
  const db = admin.firestore();
  const doc = await db
    .collection('referralVerifications')
    .doc(userId)
    .collection('trackedActions')
    .doc(actionId)
    .get();
  return doc.exists;
}

/**
 * Marks an action as counted to prevent duplicate tracking.
 * Should be called after successfully updating the checklist.
 * 
 * @param userId - The user's UID
 * @param actionType - Type of action
 * @param actionId - Unique ID of the action
 */
export async function markActionAsCounted(
  userId: string,
  actionType: string,
  actionId: string
): Promise<void> {
  const db = admin.firestore();
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

