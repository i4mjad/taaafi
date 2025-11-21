// functions/src/referral/helpers/checklistHelper.ts
import * as admin from 'firebase-admin';
// Removed incorrect import. Use admin.firestore.Timestamp type directly.
import { ChecklistItem, ReferralVerification } from '../types/referral.types';

/**
 * Checks if the user meets all verification criteria.
 * Returns true if every checklist item is marked completed.
 */
export async function checkVerificationCompletion(userId: string): Promise<boolean> {
  const doc = await admin.firestore().collection('referralVerifications').doc(userId).get();
  if (!doc.exists) return false;
  const data = doc.data() as ReferralVerification;
  const checklist = data.checklist;
  return Object.values(checklist).every((item) => item.completed);
}

/**
 * Updates a specific checklist item for a user.
 */
export async function updateChecklistItem(
  userId: string,
  itemKey: keyof ReferralVerification['checklist'],
  data: Partial<ChecklistItem>
): Promise<void> {
  const ref = admin.firestore().collection('referralVerifications').doc(userId);
  await ref.update({
    [`checklist.${itemKey}`]: { ...(await ref.get()).data()?.checklist[itemKey], ...data },
  });
}

/**
 * Calculates the overall checklist completion percentage for a user.
 */
export async function getChecklistProgress(userId: string): Promise<number> {
  const doc = await admin.firestore().collection('referralVerifications').doc(userId).get();
  if (!doc.exists) return 0;
  const data = doc.data() as ReferralVerification;
  const items = Object.values(data.checklist);
  const completed = items.filter((i) => i.completed).length;
  return (completed / items.length) * 100;
}

/**
 * Checks if the user's account age meets the minimum days requirement.
 */
export async function checkAccountAge(userId: string, minDays: number): Promise<boolean> {
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  if (!userDoc.exists) return false;
  const createdAt = (userDoc.data()?.createdAt as admin.firestore.Timestamp) ?? null;
  if (!createdAt) return false;
  const ageMs = Date.now() - createdAt.toDate().getTime();
  const ageDays = ageMs / (1000 * 60 * 60 * 24);
  return ageDays >= minDays;
}
