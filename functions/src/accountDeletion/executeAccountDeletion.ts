import * as admin from 'firebase-admin';

export interface DeletionSummary {
  userId: string;
  timestamp: string;
  startTime: number;
  collections: Record<string, number>;
  totalDocuments: number;
  errors: string[];
  success: boolean;
  initiatedBy?: string;
}

/**
 * Executes full account deletion for a given userId.
 * Handles all Firestore data cleanup and Firebase Auth deletion.
 * Can be called from the onCall function (user-initiated) or the
 * scheduled function (auto-processing after 30-day grace period).
 */
export async function executeAccountDeletion(
  userId: string,
  initiatedBy: 'user' | 'system-scheduled' | 'admin' = 'user'
): Promise<DeletionSummary> {
  const db = admin.firestore();
  const startTime = Date.now();

  const summary: DeletionSummary = {
    userId,
    timestamp: new Date().toISOString(),
    startTime,
    collections: {},
    totalDocuments: 0,
    errors: [],
    success: false,
    initiatedBy,
  };

  console.log(`👤 Starting comprehensive deletion for user: ${userId} (initiatedBy: ${initiatedBy})`);

  try {
    // 1. Delete Community Data
    console.log('🏘️ Deleting community data...');
    await deleteCommunityData(db, userId, summary);

    // 2. Delete Vault Data
    console.log('🏦 Deleting vault data...');
    await deleteVaultData(db, userId, summary);

    // 3. Handle Referral Data (notify referrer, update stats)
    console.log('🔗 Handling referral data...');
    await handleReferralDataOnDeletion(db, userId, summary);

    // 4. Delete User Profile and Main Document
    console.log('👤 Deleting user profile...');
    await deleteUserProfile(db, userId, summary);

    // 5. Delete Authentication Records
    console.log('🔐 Deleting authentication records...');
    await deleteAuthenticationData(db, userId, summary);

    // 6. Delete Firebase Auth user (Admin SDK — works for both user and system-initiated deletions)
    console.log('🔑 Deleting Firebase Auth user...');
    await deleteFirebaseAuthUser(userId, summary);

    // 7. Create deletion audit record
    console.log('📝 Creating deletion audit record...');
    await createDeletionAuditRecord(db, summary);

    const duration = Date.now() - startTime;
    summary.success = true;

    console.log(`✅ User deletion completed successfully in ${duration}ms`);
    console.log('📊 Deletion summary:', summary);

    return summary;
  } catch (error: any) {
    console.error(`❌ Error during user deletion for ${userId}:`, error);
    summary.errors.push(error.message);

    try {
      await createDeletionAuditRecord(db, summary);
    } catch (auditError) {
      console.error('❌ Failed to create deletion audit record:', auditError);
    }

    throw error;
  }
}

async function deleteCommunityData(
  db: FirebaseFirestore.Firestore,
  userId: string,
  summary: DeletionSummary
): Promise<void> {
  const batch = db.batch();
  let operationCount = 0;

  try {
    // Soft delete community profile
    const communityProfileRef = db.collection('communityProfiles').doc(userId);
    const profileSnapshot = await communityProfileRef.get();

    if (profileSnapshot.exists) {
      batch.update(communityProfileRef, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        displayName: '[Deleted User]',
        avatarUrl: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      operationCount++;
      summary.collections.communityProfiles = 1;
    }

    // Soft delete user posts
    const postsQuery = await db
      .collection('forumPosts')
      .where('authorCPId', '==', userId)
      .get();

    postsQuery.docs.forEach((doc) => {
      batch.update(doc.ref, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        title: '[Post by deleted user]',
        body: '[This post was created by a user who has deleted their account]',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      operationCount++;
    });
    summary.collections.forumPosts = postsQuery.docs.length;

    // Soft delete user comments
    const commentsQuery = await db
      .collection('comments')
      .where('authorCPId', '==', userId)
      .get();

    commentsQuery.docs.forEach((doc) => {
      batch.update(doc.ref, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        body: '[Comment by deleted user]',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      operationCount++;
    });
    summary.collections.comments = commentsQuery.docs.length;

    // Soft delete user interactions
    const interactionsQuery = await db
      .collection('interactions')
      .where('userCPId', '==', userId)
      .get();

    interactionsQuery.docs.forEach((doc) => {
      batch.update(doc.ref, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      operationCount++;
    });
    summary.collections.interactions = interactionsQuery.docs.length;

    // Hard delete community interest tracking
    const interestRef = db.collection('communityInterest').doc(userId);
    const interestSnapshot = await interestRef.get();

    if (interestSnapshot.exists) {
      batch.delete(interestRef);
      operationCount++;
      summary.collections.communityInterest = 1;
    }

    if (operationCount > 0) {
      await batch.commit();
      console.log(`✅ Community data deletion completed: ${operationCount} operations`);
    } else {
      console.log('ℹ️ No community data found for user');
    }
  } catch (error: any) {
    console.error('❌ Error deleting community data:', error);
    summary.errors.push(`Community deletion failed: ${error.message}`);
    throw error;
  }
}

async function deleteVaultData(
  db: FirebaseFirestore.Firestore,
  userId: string,
  summary: DeletionSummary
): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);

    // Simple subcollections — delete all docs directly
    // Note: 'followUps' (capital U) is included alongside legacy 'followups' casing
    const simpleSubcollections = [
      'activities',
      'emotions',
      'followups',
      'followUps',
      'diaries',
      'relapses',
      'streaks',
      'settings',
      'userNotes',
    ];

    for (const subcollection of simpleSubcollections) {
      const snapshot = await userRef.collection(subcollection).get();

      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        summary.collections[subcollection] = snapshot.docs.length;
        console.log(`✅ Deleted ${snapshot.docs.length} docs from users/${userId}/${subcollection}`);
      } else {
        summary.collections[subcollection] = 0;
      }
    }

    // ongoing_activities has a nested scheduledTasks subcollection per doc
    const ongoingActivitiesSnapshot = await userRef.collection('ongoing_activities').get();

    if (!ongoingActivitiesSnapshot.empty) {
      let ongoingCount = 0;
      let scheduledTasksCount = 0;

      for (const activityDoc of ongoingActivitiesSnapshot.docs) {
        // Delete nested scheduledTasks first
        const tasksSnapshot = await activityDoc.ref.collection('scheduledTasks').get();
        if (!tasksSnapshot.empty) {
          const tasksBatch = db.batch();
          tasksSnapshot.docs.forEach((task) => tasksBatch.delete(task.ref));
          await tasksBatch.commit();
          scheduledTasksCount += tasksSnapshot.docs.length;
        }
        ongoingCount++;
      }

      // Now delete the parent docs
      const parentBatch = db.batch();
      ongoingActivitiesSnapshot.docs.forEach((doc) => parentBatch.delete(doc.ref));
      await parentBatch.commit();

      summary.collections['ongoing_activities'] = ongoingCount;
      summary.collections['ongoing_activities/scheduledTasks'] = scheduledTasksCount;
      console.log(
        `✅ Deleted ${ongoingCount} ongoing_activities and ${scheduledTasksCount} scheduledTasks`
      );
    } else {
      summary.collections['ongoing_activities'] = 0;
    }
  } catch (error: any) {
    console.error('❌ Error deleting vault data:', error);
    summary.errors.push(`Vault deletion failed: ${error.message}`);
    throw error;
  }
}

async function handleReferralDataOnDeletion(
  db: FirebaseFirestore.Firestore,
  userId: string,
  summary: DeletionSummary
): Promise<void> {
  try {
    const { handleReferralUserDeletion } = await import('../referral/handlers/userDeletionHandler');
    const result = await handleReferralUserDeletion(userId);

    summary.collections.referralVerifications = result.verificationsMarked;
    summary.collections.referralNotifications = result.referrerNotified ? 1 : 0;
    summary.collections.referralStats = result.statsUpdated ? 1 : 0;

    if (result.errors.length > 0) {
      console.warn(`⚠️ Referral cleanup had errors: ${result.errors.join(', ')}`);
      summary.errors.push(...result.errors);
    } else {
      console.log('✅ Referral data handled successfully');
    }
  } catch (error: any) {
    console.error('❌ Error handling referral data:', error);
    summary.errors.push(`Referral cleanup failed: ${error.message}`);
    // Don't throw — referral cleanup failure should not block account deletion
  }
}

async function deleteUserProfile(
  db: FirebaseFirestore.Firestore,
  userId: string,
  summary: DeletionSummary
): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);
    const userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      await userRef.delete();
      summary.collections.users = 1;
      console.log('✅ User profile document deleted');
    } else {
      summary.collections.users = 0;
      console.log('ℹ️ No user profile document found');
    }
  } catch (error: any) {
    console.error('❌ Error deleting user profile:', error);
    summary.errors.push(`User profile deletion failed: ${error.message}`);
    throw error;
  }
}

async function deleteAuthenticationData(
  db: FirebaseFirestore.Firestore,
  userId: string,
  summary: DeletionSummary
): Promise<void> {
  const authCollections = ['userSessions', 'refreshTokens', 'deviceTokens', 'loginHistory'];

  for (const collection of authCollections) {
    try {
      const snap = await db.collection(collection).where('userId', '==', userId).get();

      if (!snap.empty) {
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        summary.collections[collection] = snap.docs.length;
        console.log(`✅ Deleted ${snap.docs.length} docs from ${collection}`);
      } else {
        summary.collections[collection] = 0;
      }
    } catch {
      console.log(`ℹ️ Collection ${collection} may not exist or is empty`);
      summary.collections[collection] = 0;
    }
  }
}

async function deleteFirebaseAuthUser(
  userId: string,
  summary: DeletionSummary
): Promise<void> {
  try {
    await admin.auth().deleteUser(userId);
    summary.collections.firebaseAuth = 1;
    console.log('✅ Firebase Auth user deleted');
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      // Already deleted (e.g., user deleted themselves client-side first)
      summary.collections.firebaseAuth = 0;
      console.log('ℹ️ Firebase Auth user already deleted or not found');
    } else {
      console.error('❌ Error deleting Firebase Auth user:', error);
      summary.errors.push(`Firebase Auth deletion failed: ${error.message}`);
      // Don't throw — Firestore data is already cleaned up; auth deletion failure is non-critical
    }
  }
}

async function createDeletionAuditRecord(
  db: FirebaseFirestore.Firestore,
  summary: DeletionSummary
): Promise<void> {
  try {
    summary.totalDocuments = Object.values(summary.collections).reduce(
      (total, count) => total + count,
      0
    );

    await db.collection('deletedUsers').doc(summary.userId).set({
      ...summary,
      auditCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Deletion audit record created');
  } catch (error: any) {
    console.error('❌ Error creating deletion audit record:', error);
    throw error;
  }
}
