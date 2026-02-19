import * as admin from 'firebase-admin';

/**
 * Security helper functions for attachment system
 */

/**
 * Check if a user is the author of a post
 */
export async function isPostAuthor(postId: string, userId: string): Promise<boolean> {
  try {
    const postDoc = await admin.firestore().collection('forumPosts').doc(postId).get();
    if (!postDoc.exists) {
      return false;
    }
    
    const postData = postDoc.data()!;
    return postData.authorId === userId;
  } catch (error) {
    console.error(`Error checking post author for ${postId}:`, error);
    return false;
  }
}

/**
 * Check if a user is a Plus user
 */
export async function isPlusUser(userId: string): Promise<boolean> {
  try {
    // First try to get from custom claims
    const userRecord = await admin.auth().getUser(userId);
    const customClaims = userRecord.customClaims;
    
    if (customClaims && customClaims.isPlusUser === true) {
      return true;
    }
    
    // Fallback: check community profile
    const cpDoc = await admin.firestore()
      .collection('communityProfiles')
      .doc(userId)
      .get();
    
    if (cpDoc.exists) {
      const cpData = cpDoc.data()!;
      return cpData.isPlusUser === true;
    }
    
    return false;
  } catch (error) {
    console.error(`Error checking Plus status for ${userId}:`, error);
    return false;
  }
}

/**
 * Validate attachment type
 */
export function validAttachmentType(type: string): boolean {
  return ['image', 'poll', 'group_invite'].includes(type);
}

/**
 * Check if a poll is open
 */
export async function pollOpen(postId: string, pollId: string): Promise<boolean> {
  try {
    const pollDoc = await admin.firestore()
      .collection('forumPosts')
      .doc(postId)
      .collection('attachments')
      .doc(pollId)
      .get();
    
    if (!pollDoc.exists) {
      return false;
    }
    
    const pollData = pollDoc.data()!;
    return pollData.type === 'poll' && !pollData.isClosed;
  } catch (error) {
    console.error(`Error checking poll status for ${pollId}:`, error);
    return false;
  }
}

/**
 * Validate vote selection for a poll
 */
export async function validVoteSelection(
  postId: string,
  pollId: string,
  selectedOptionIds: string[]
): Promise<boolean> {
  try {
    const pollDoc = await admin.firestore()
      .collection('forumPosts')
      .doc(postId)
      .collection('attachments')
      .doc(pollId)
      .get();
    
    if (!pollDoc.exists) {
      return false;
    }
    
    const pollData = pollDoc.data()!;
    if (pollData.type !== 'poll') {
      return false;
    }
    
    const options: Array<{ id: string }> = pollData.options || [];
    const validOptionIds = new Set(options.map(opt => opt.id));
    
    // Check if all selected options are valid
    const allValid = selectedOptionIds.every(id => validOptionIds.has(id));
    if (!allValid) {
      return false;
    }
    
    // Check selection mode constraints
    if (pollData.selectionMode === 'single' && selectedOptionIds.length > 1) {
      return false;
    }
    
    return true;
  } catch (error) {
    console.error(`Error validating vote selection for ${pollId}:`, error);
    return false;
  }
}

/**
 * Check if user is a member of a group (for invite creation)
 */
export async function isGroupMember(userId: string, groupId: string): Promise<boolean> {
  try {
    const membershipQuery = await admin.firestore()
      .collection('group_memberships')
      .where('cpId', '==', userId)
      .where('groupId', '==', groupId)
      .where('isActive', '==', true)
      .limit(1)
      .get();
    
    return !membershipQuery.empty;
  } catch (error) {
    console.error(`Error checking group membership for ${userId} in ${groupId}:`, error);
    return false;
  }
}

/**
 * Generate stable attachment ID
 */
export function generateStableAttachmentId(postId: string, contentHash: string): string {
  const shortHash = contentHash.length > 12 ? contentHash.substring(0, 12) : contentHash;
  return `${postId}-${shortHash}`;
}

/**
 * Validate attachment ID format
 */
export function validAttachmentIdFormat(attachmentId: string, postId: string): boolean {
  // Expected format: ${postId}-${hash}
  const expectedPrefix = `${postId}-`;
  return attachmentId.startsWith(expectedPrefix) && attachmentId.length > expectedPrefix.length;
}
