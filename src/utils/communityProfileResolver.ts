import { doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export interface ResolvedProfile {
  cpId: string;
  userUID: string;
  displayName: string;
}

/**
 * Resolves a community profile ID to a user UID and display name.
 *
 * The communityProfiles collection stores documents where:
 * - The document ID often matches the user UID
 * - The `userUID` field (if present) is the canonical link to the `users` collection
 *
 * Resolution order:
 * 1. Use `userUID` field if it exists
 * 2. Fall back to the document `id` (which per convention matches user UID)
 */
export async function resolveCommunityProfile(
  cpId: string
): Promise<ResolvedProfile | null> {
  try {
    const cpDoc = await getDoc(doc(db, 'communityProfiles', cpId));

    if (!cpDoc.exists()) {
      return null;
    }

    const data = cpDoc.data();
    const userUID = data.userUID || cpDoc.id;
    const displayName = data.displayName || cpId;

    return {
      cpId,
      userUID,
      displayName,
    };
  } catch (error) {
    console.error('Error resolving community profile:', error);
    return null;
  }
}
