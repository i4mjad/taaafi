import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface BackfillResult {
  success: boolean;
  groupId: string;
  cpId: string;
  messagesBackfilled: number;
  achievementsAwarded: number;
  messageCount: number;
  engagementScore: number;
  lastActiveAt: string | null;
  error?: string;
}

/**
 * Cloud Function to backfill activity data for a single member
 * 
 * Security: User can ONLY backfill their OWN data
 * 
 * @param data.groupId - The group ID to backfill activity for
 */
export const backfillMemberActivity = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
  })
  .https.onCall(async (data, context): Promise<BackfillResult> => {
    
    // 1. Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be authenticated to backfill activity'
      );
    }

    const { groupId } = data;
    
    if (!groupId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'groupId is required'
      );
    }

    try {
      const db = admin.firestore();
      
      // 2. Get user's community profile ID from their auth UID
      const userCpId = await getUserCommunityProfileId(db, context.auth.uid);
      
      console.log(`Backfilling activity for user ${userCpId} in group ${groupId}`);

      // 3. Verify user is a member of this group
      const membershipId = `${groupId}_${userCpId}`;
      const membershipDoc = await db
        .collection('group_memberships')
        .doc(membershipId)
        .get();

      if (!membershipDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'You are not a member of this group'
        );
      }

      const memberData = membershipDoc.data()!;

      if (!memberData.isActive) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'You are not an active member of this group'
        );
      }

      // 4. Count historical messages (exclude deleted/hidden/blocked)
      const messagesQuery = await db
        .collection('group_messages')
        .where('groupId', '==', groupId)
        .where('senderCpId', '==', userCpId)
        .where('isDeleted', '==', false)
        .where('isHidden', '==', false)
        .orderBy('createdAt', 'desc')
        .get();

      // Filter out blocked messages (moderation status is nested, so filter in code)
      const validMessages = messagesQuery.docs.filter(doc => {
        const data = doc.data();
        const moderation = data.moderation as any;
        return !moderation || moderation.status !== 'blocked';
      });

      const messageCount = validMessages.length;
      
      console.log(`Found ${messageCount} valid messages for user ${userCpId}`);

      // 5. Get most recent message timestamp
      const lastActiveAt = validMessages.length > 0
        ? validMessages[0].data().createdAt
        : null;

      // 6. Calculate engagement score (same formula as real-time tracking)
      const engagementScore = Math.min(messageCount * 2, 999);

      // 7. Update membership document
      await membershipDoc.ref.update({
        messageCount,
        lastActiveAt: lastActiveAt || admin.firestore.FieldValue.delete(),
        engagementScore,
      });

      console.log(`✅ Updated membership: ${messageCount} messages, score: ${engagementScore}`);

      // 8. Award retroactive achievements
      const achievementsAwarded = await awardRetroactiveAchievements(
        db,
        groupId,
        userCpId,
        memberData,
        messageCount
      );

      // 9. Return success result
      return {
        success: true,
        groupId,
        cpId: userCpId,
        messagesBackfilled: messageCount,
        achievementsAwarded,
        messageCount,
        engagementScore,
        lastActiveAt: lastActiveAt ? lastActiveAt.toDate().toISOString() : null,
      };

    } catch (error: any) {
      console.error('Backfill failed:', error);
      
      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      // Wrap other errors
      throw new functions.https.HttpsError(
        'internal',
        `Backfill failed: ${error.message}`
      );
    }
  });

/**
 * Get user's community profile ID from their auth UID
 */
async function getUserCommunityProfileId(
  db: admin.firestore.Firestore,
  userUID: string
): Promise<string> {
  const profileSnapshot = await db
    .collection('communityProfiles')
    .where('userUID', '==', userUID)
    .limit(1)
    .get();

  if (profileSnapshot.empty) {
    throw new functions.https.HttpsError(
      'not-found',
      'Community profile not found'
    );
  }

  return profileSnapshot.docs[0].id;
}

/**
 * Award retroactive achievements based on join date and message count
 */
async function awardRetroactiveAchievements(
  db: admin.firestore.Firestore,
  groupId: string,
  cpId: string,
  memberData: any,
  messageCount: number
): Promise<number> {
  
  const joinedAt = memberData.joinedAt.toDate();
  const daysSinceJoin = Math.floor(
    (Date.now() - joinedAt.getTime()) / (1000 * 60 * 60 * 24)
  );

  console.log(`User joined ${daysSinceJoin} days ago`);

  // Get existing achievements to avoid duplicates
  // Query by cpId only to avoid composite index requirement
  const existingSnapshot = await db
    .collection('groupAchievements')
    .where('cpId', '==', cpId)
    .get();

  // Filter by groupId in code
  const existingTypes = new Set(
    existingSnapshot.docs
      .filter(doc => doc.data().groupId === groupId)
      .map(doc => doc.data().achievementType)
  );

  const achievementsToAward: Array<{
    type: string;
    title: string;
    description: string;
  }> = [];

  // Check each achievement type
  
  // Welcome - always award if not already earned
  if (!existingTypes.has('welcome')) {
    achievementsToAward.push({
      type: 'welcome',
      title: 'welcome-achievement',
      description: 'welcome-desc',
    });
  }

  // First Message - only if they have sent messages
  if (messageCount > 0 && !existingTypes.has('first_message')) {
    achievementsToAward.push({
      type: 'first_message',
      title: 'first_message-achievement',
      description: 'first_message-desc',
    });
  }

  // Week Warrior - if member for 7+ days
  if (daysSinceJoin >= 7 && !existingTypes.has('week_warrior')) {
    achievementsToAward.push({
      type: 'week_warrior',
      title: 'week_warrior-achievement',
      description: 'week_warrior-desc',
    });
  }

  // Month Master - if member for 30+ days
  if (daysSinceJoin >= 30 && !existingTypes.has('month_master')) {
    achievementsToAward.push({
      type: 'month_master',
      title: 'month_master-achievement',
      description: 'month_master-desc',
    });
  }

  // Award achievements in batch
  if (achievementsToAward.length > 0) {
    const batch = db.batch();

    for (const achievement of achievementsToAward) {
      const achievementRef = db.collection('groupAchievements').doc();
      
      batch.set(achievementRef, {
        groupId,
        cpId,
        achievementType: achievement.type,
        title: achievement.title,
        description: achievement.description,
        earnedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update community profile's groupAchievements array
      const profileRef = db.collection('communityProfiles').doc(cpId);
      batch.update(profileRef, {
        groupAchievements: admin.firestore.FieldValue.arrayUnion(achievementRef.id),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`🏆 Awarded ${achievementsToAward.length} achievements to ${cpId}`);
  }

  return achievementsToAward.length;
}

