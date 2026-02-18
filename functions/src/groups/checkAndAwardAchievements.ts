import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Scheduled function to check and award achievements for all group members
 * 
 * Runs hourly to check:
 * - Welcome achievement (on join)
 * - First Message achievement (messageCount >= 1)
 * - Week Warrior (7+ days membership)
 * - Month Master (30+ days membership)
 * - Helpful (10+ supportive reactions) - TODO
 * - Top Contributor (most active member) - TODO
 * 
 * This is the SINGLE SOURCE OF TRUTH for achievement awarding
 */
export const checkAndAwardAchievements = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 540, // 9 minutes
    memory: '1GB',
  })
  .pubsub.schedule('every 1 hours')
  .onRun(async (context) => {
    const startTime = Date.now();
    console.log('🏆 [ACHIEVEMENTS] Starting hourly achievement check...');

    const db = admin.firestore();
    
    const stats = {
      membershipsProcessed: 0,
      achievementsAwarded: 0,
      errors: 0,
      duration: 0,
    };

    try {
      // Get all active group memberships
      const membershipsSnapshot = await db
        .collection('group_memberships')
        .where('isActive', '==', true)
        .get();

      console.log(`🔍 [ACHIEVEMENTS] Found ${membershipsSnapshot.size} active memberships`);

      // Process each membership
      for (const membershipDoc of membershipsSnapshot.docs) {
        try {
          const memberData = membershipDoc.data();
          const { groupId, cpId, messageCount, joinedAt } = memberData;

          const newAchievements = await checkMemberAchievements(
            db,
            groupId,
            cpId,
            messageCount || 0,
            joinedAt.toDate()
          );

          stats.achievementsAwarded += newAchievements;
          stats.membershipsProcessed++;

        } catch (error: any) {
          console.error(`❌ [ACHIEVEMENTS] Error processing membership ${membershipDoc.id}:`, error.message);
          stats.errors++;
        }
      }

      stats.duration = Date.now() - startTime;
      
      console.log(`✅ [ACHIEVEMENTS] Check complete:`, stats);
      
    } catch (error: any) {
      console.error('❌ [ACHIEVEMENTS] Fatal error:', error);
      throw error;
    }
  });

/**
 * Check and award achievements for a single member
 * 
 * @returns Number of new achievements awarded
 */
async function checkMemberAchievements(
  db: admin.firestore.Firestore,
  groupId: string,
  cpId: string,
  messageCount: number,
  joinedAt: Date
): Promise<number> {
  
  const daysSinceJoin = Math.floor(
    (Date.now() - joinedAt.getTime()) / (1000 * 60 * 60 * 24)
  );

  // Get existing achievements (query by cpId only to avoid composite index)
  const existingSnapshot = await db
    .collection('groupAchievements')
    .where('cpId', '==', cpId)
    .get();

  // Filter by groupId in code
  const existingForThisGroup = existingSnapshot.docs
    .filter(doc => doc.data().groupId === groupId);

  const existingTypes = new Set(
    existingForThisGroup.map(doc => doc.data().achievementType)
  );

  const achievementsToAward: Array<{
    type: string;
    title: string;
    description: string;
  }> = [];

  // === ACHIEVEMENT CHECKS ===

  // 1. Welcome - Always awarded (should have been on join, but check anyway)
  if (!existingTypes.has('welcome')) {
    achievementsToAward.push({
      type: 'welcome',
      title: 'welcome-achievement',
      description: 'welcome-desc',
    });
  }

  // 2. First Message - Awarded when user sends their first message
  if (messageCount >= 1 && !existingTypes.has('first_message')) {
    achievementsToAward.push({
      type: 'first_message',
      title: 'first_message-achievement',
      description: 'first_message-desc',
    });
  }

  // 3. Week Warrior - Awarded after 7 days of membership
  if (daysSinceJoin >= 7 && !existingTypes.has('week_warrior')) {
    achievementsToAward.push({
      type: 'week_warrior',
      title: 'week_warrior-achievement',
      description: 'week_warrior-desc',
    });
  }

  // 4. Month Master - Awarded after 30 days of membership
  if (daysSinceJoin >= 30 && !existingTypes.has('month_master')) {
    achievementsToAward.push({
      type: 'month_master',
      title: 'month_master-achievement',
      description: 'month_master-desc',
    });
  }

  // TODO: Add Helpful achievement (10+ supportive reactions)
  // TODO: Add Top Contributor achievement (most active member)

  // Award new achievements
  if (achievementsToAward.length > 0) {
    await awardAchievements(db, groupId, cpId, achievementsToAward);
    console.log(`🏆 [ACHIEVEMENTS] Awarded ${achievementsToAward.length} to ${cpId} in group ${groupId}`);
  }

  return achievementsToAward.length;
}

/**
 * Award multiple achievements in a batch
 */
async function awardAchievements(
  db: admin.firestore.Firestore,
  groupId: string,
  cpId: string,
  achievements: Array<{ type: string; title: string; description: string }>
): Promise<void> {
  
  const batch = db.batch();

  for (const achievement of achievements) {
    // Create achievement document
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
}

