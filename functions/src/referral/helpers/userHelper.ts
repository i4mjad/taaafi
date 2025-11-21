// functions/src/referral/helpers/userHelper.ts
import * as admin from 'firebase-admin';

/**
 * Converts a Community Profile ID to a User UID.
 * Returns null if the CP document doesn't exist or has no userUID.
 */
export async function getUserIdFromCPId(cpId: string): Promise<string | null> {
  const db = admin.firestore();
  const cpDoc = await db.collection('communityProfiles').doc(cpId).get();
  if (!cpDoc.exists) return null;
  return cpDoc.data()?.userUID || null;
}

/**
 * In-memory cache for CP ID -> User UID lookups to improve performance.
 * Cache is cleared on function cold starts.
 */
const cpIdCache = new Map<string, string>();

/**
 * Same as getUserIdFromCPId but uses an in-memory cache for performance.
 * Useful for high-frequency trigger invocations.
 */
export async function getUserIdFromCPIdCached(cpId: string): Promise<string | null> {
  if (cpIdCache.has(cpId)) {
    return cpIdCache.get(cpId)!;
  }
  const userId = await getUserIdFromCPId(cpId);
  if (userId) {
    cpIdCache.set(cpId, userId);
  }
  return userId;
}

/**
 * Clears the CP ID cache. Useful for testing or forcing fresh lookups.
 */
export function clearCPIdCache(): void {
  cpIdCache.clear();
}

