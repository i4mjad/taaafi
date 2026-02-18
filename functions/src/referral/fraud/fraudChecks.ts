// functions/src/referral/fraud/fraudChecks.ts
import * as admin from 'firebase-admin';
import { FraudCheckResult } from '../types/referral.types';

const db = admin.firestore();

/**
 * Check 1: Device ID Overlap
 * Checks if the referee and referrer share any device IDs
 * Score: 50 if overlap detected, 0 otherwise
 */
export async function checkDeviceOverlap(
  refereeId: string,
  referrerId: string
): Promise<FraudCheckResult> {
  try {
    // Get both users' device IDs
    const [refereeDoc, referrerDoc] = await Promise.all([
      db.collection('users').doc(refereeId).get(),
      db.collection('users').doc(referrerId).get(),
    ]);

    if (!refereeDoc.exists || !referrerDoc.exists) {
      return {
        checkName: 'device_overlap',
        score: 0,
        flag: null,
        details: { error: 'User documents not found' },
      };
    }

    const refereeDevices = (refereeDoc.data()?.devicesIds || []) as string[];
    const referrerDevices = (referrerDoc.data()?.devicesIds || []) as string[];

    // Check for any overlap
    const overlap = refereeDevices.some((device) =>
      referrerDevices.includes(device)
    );

    if (overlap) {
      const sharedDevices = refereeDevices.filter((device) =>
        referrerDevices.includes(device)
      );
      return {
        checkName: 'device_overlap',
        score: 50,
        flag: 'same_device_as_referrer',
        details: { sharedDevices },
      };
    }

    return {
      checkName: 'device_overlap',
      score: 0,
      flag: null,
    };
  } catch (error) {
    console.error('Error in checkDeviceOverlap:', error);
    return {
      checkName: 'device_overlap',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

/**
 * Check 2: Rapid Posting Pattern
 * Analyzes time between forum posts
 * Score: 25 if average time < 2 minutes
 */
export async function checkPostingPattern(userId: string): Promise<FraudCheckResult> {
  try {
    // Get user's CP ID first
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {
        checkName: 'posting_pattern',
        score: 0,
        flag: null,
        details: { error: 'User not found' },
      };
    }

    // Find the user's community profile
    const cpQuery = await db
      .collection('communityProfiles')
      .where('userUID', '==', userId)
      .limit(1)
      .get();

    if (cpQuery.empty) {
      return {
        checkName: 'posting_pattern',
        score: 0,
        flag: null,
        details: { error: 'Community profile not found' },
      };
    }

    const cpId = cpQuery.docs[0].id;

    // Get user's forum posts ordered by creation time
    const postsQuery = await db
      .collection('forumPosts')
      .where('authorCPId', '==', cpId)
      .orderBy('createdAt', 'asc')
      .get();

    if (postsQuery.size < 2) {
      return {
        checkName: 'posting_pattern',
        score: 0,
        flag: null,
        details: { postCount: postsQuery.size },
      };
    }

    // Calculate average time between posts
    const timestamps: number[] = [];
    postsQuery.forEach((doc) => {
      const createdAt = doc.data().createdAt;
      if (createdAt) {
        timestamps.push(createdAt.toMillis());
      }
    });

    if (timestamps.length < 2) {
      return {
        checkName: 'posting_pattern',
        score: 0,
        flag: null,
      };
    }

    // Calculate average time difference in minutes
    const timeDifferences: number[] = [];
    for (let i = 1; i < timestamps.length; i++) {
      const diffMinutes = (timestamps[i] - timestamps[i - 1]) / (1000 * 60);
      timeDifferences.push(diffMinutes);
    }

    const averageMinutes =
      timeDifferences.reduce((a, b) => a + b, 0) / timeDifferences.length;

    if (averageMinutes < 2) {
      return {
        checkName: 'posting_pattern',
        score: 25,
        flag: 'rapid_posting',
        details: { averageMinutes, postCount: postsQuery.size },
      };
    }

    return {
      checkName: 'posting_pattern',
      score: 0,
      flag: null,
      details: { averageMinutes, postCount: postsQuery.size },
    };
  } catch (error) {
    console.error('Error in checkPostingPattern:', error);
    return {
      checkName: 'posting_pattern',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

/**
 * Check 3: Interaction Concentration
 * Checks if user interacts with very few unique users
 * Score: 40 if interactions >= 5 but uniqueUsers < 3
 */
export async function checkInteractionConcentration(
  userId: string
): Promise<FraudCheckResult> {
  try {
    // Get verification document
    const verificationDoc = await db
      .collection('referralVerifications')
      .doc(userId)
      .get();

    if (!verificationDoc.exists) {
      return {
        checkName: 'interaction_concentration',
        score: 0,
        flag: null,
        details: { error: 'Verification document not found' },
      };
    }

    const verification = verificationDoc.data();
    const interactionsCurrent = verification?.checklist?.interactions5?.current || 0;
    const uniqueUsers = verification?.checklist?.interactions5?.uniqueUsers || [];

    // If they have 5+ interactions but with < 3 unique users
    if (interactionsCurrent >= 5 && uniqueUsers.length < 3) {
      return {
        checkName: 'interaction_concentration',
        score: 40,
        flag: 'concentrated_interactions',
        details: {
          interactionCount: interactionsCurrent,
          uniqueUserCount: uniqueUsers.length,
        },
      };
    }

    return {
      checkName: 'interaction_concentration',
      score: 0,
      flag: null,
      details: {
        interactionCount: interactionsCurrent,
        uniqueUserCount: uniqueUsers.length,
      },
    };
  } catch (error) {
    console.error('Error in checkInteractionConcentration:', error);
    return {
      checkName: 'interaction_concentration',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

/**
 * Check 4: Rapid Group Messaging
 * Checks if 3+ messages sent within 5 minutes
 * Score: 30 if rapid messaging detected
 */
export async function checkGroupMessagingPattern(
  userId: string
): Promise<FraudCheckResult> {
  try {
    // Get user's CP ID
    const cpQuery = await db
      .collection('communityProfiles')
      .where('userUID', '==', userId)
      .limit(1)
      .get();

    if (cpQuery.empty) {
      return {
        checkName: 'group_messaging_pattern',
        score: 0,
        flag: null,
        details: { error: 'Community profile not found' },
      };
    }

    const cpId = cpQuery.docs[0].id;

    // Get user's group messages ordered by time
    const messagesQuery = await db
      .collection('group_messages')
      .where('senderCpId', '==', cpId)
      .orderBy('createdAt', 'asc')
      .get();

    if (messagesQuery.size < 3) {
      return {
        checkName: 'group_messaging_pattern',
        score: 0,
        flag: null,
        details: { messageCount: messagesQuery.size },
      };
    }

    // Check for rapid messaging (3+ messages within 5 minutes)
    const timestamps: number[] = [];
    messagesQuery.forEach((doc) => {
      const createdAt = doc.data().createdAt;
      if (createdAt) {
        timestamps.push(createdAt.toMillis());
      }
    });

    // Check sliding window of 3 messages
    for (let i = 0; i <= timestamps.length - 3; i++) {
      const windowStart = timestamps[i];
      const windowEnd = timestamps[i + 2];
      const windowMinutes = (windowEnd - windowStart) / (1000 * 60);

      if (windowMinutes <= 5) {
        return {
          checkName: 'group_messaging_pattern',
          score: 30,
          flag: 'rapid_group_messaging',
          details: {
            windowMinutes,
            messageCount: messagesQuery.size,
          },
        };
      }
    }

    return {
      checkName: 'group_messaging_pattern',
      score: 0,
      flag: null,
      details: { messageCount: messagesQuery.size },
    };
  } catch (error) {
    console.error('Error in checkGroupMessagingPattern:', error);
    return {
      checkName: 'group_messaging_pattern',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

/**
 * Check 5: Account Age vs Activity Burst
 * New account with high activity is suspicious
 * Score: 30 if account < 24 hours and completed 4+ checklist items
 */
export async function checkActivityBurst(userId: string): Promise<FraudCheckResult> {
  try {
    // Get user document for account age
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {
        checkName: 'activity_burst',
        score: 0,
        flag: null,
        details: { error: 'User not found' },
      };
    }

    const userFirstDate = userDoc.data()?.userFirstDate;
    if (!userFirstDate) {
      return {
        checkName: 'activity_burst',
        score: 0,
        flag: null,
        details: { error: 'userFirstDate not found' },
      };
    }

    // Calculate account age in hours
    const accountAgeHours =
      (Date.now() - userFirstDate.toMillis()) / (1000 * 60 * 60);

    // Get verification document to count completed items
    const verificationDoc = await db
      .collection('referralVerifications')
      .doc(userId)
      .get();

    if (!verificationDoc.exists) {
      return {
        checkName: 'activity_burst',
        score: 0,
        flag: null,
        details: { error: 'Verification document not found' },
      };
    }

    const checklist = verificationDoc.data()?.checklist;
    let completedCount = 0;

    if (checklist) {
      if (checklist.forumPosts3?.completed) completedCount++;
      if (checklist.interactions5?.completed) completedCount++;
      if (checklist.groupJoined?.completed) completedCount++;
      if (checklist.groupMessages3?.completed) completedCount++;
      if (checklist.activityStarted?.completed) completedCount++;
    }

    // If account < 24 hours and completed 4+ items
    if (accountAgeHours < 24 && completedCount >= 4) {
      return {
        checkName: 'activity_burst',
        score: 30,
        flag: 'new_account_high_activity',
        details: {
          accountAgeHours: Math.round(accountAgeHours * 100) / 100,
          completedItems: completedCount,
        },
      };
    }

    return {
      checkName: 'activity_burst',
      score: 0,
      flag: null,
      details: {
        accountAgeHours: Math.round(accountAgeHours * 100) / 100,
        completedItems: completedCount,
      },
    };
  } catch (error) {
    console.error('Error in checkActivityBurst:', error);
    return {
      checkName: 'activity_burst',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

/**
 * Check 6: Content Quality
 * Low-quality posts (very short) are suspicious
 * Score: 20 if average word count < 10
 */
export async function checkContentQuality(userId: string): Promise<FraudCheckResult> {
  try {
    // Get user's CP ID
    const cpQuery = await db
      .collection('communityProfiles')
      .where('userUID', '==', userId)
      .limit(1)
      .get();

    if (cpQuery.empty) {
      return {
        checkName: 'content_quality',
        score: 0,
        flag: null,
        details: { error: 'Community profile not found' },
      };
    }

    const cpId = cpQuery.docs[0].id;

    // Get user's forum posts
    const postsQuery = await db
      .collection('forumPosts')
      .where('authorCPId', '==', cpId)
      .get();

    if (postsQuery.size === 0) {
      return {
        checkName: 'content_quality',
        score: 0,
        flag: null,
        details: { postCount: 0 },
      };
    }

    // Calculate average word count
    let totalWords = 0;
    postsQuery.forEach((doc) => {
      const body = doc.data().body || '';
      const title = doc.data().title || '';
      const words = (body + ' ' + title).trim().split(/\s+/).length;
      totalWords += words;
    });

    const averageWords = totalWords / postsQuery.size;

    if (averageWords < 10) {
      return {
        checkName: 'content_quality',
        score: 20,
        flag: 'low_quality_content',
        details: {
          averageWords: Math.round(averageWords * 100) / 100,
          postCount: postsQuery.size,
        },
      };
    }

    return {
      checkName: 'content_quality',
      score: 0,
      flag: null,
      details: {
        averageWords: Math.round(averageWords * 100) / 100,
        postCount: postsQuery.size,
      },
    };
  } catch (error) {
    console.error('Error in checkContentQuality:', error);
    return {
      checkName: 'content_quality',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

/**
 * Check 7: Email Pattern
 * Checks for Gmail alias pattern (user+1@gmail.com)
 * Score: 10 if pattern detected
 */
export async function checkEmailPattern(userId: string): Promise<FraudCheckResult> {
  try {
    // Get user email from Auth
    const userRecord = await admin.auth().getUser(userId);
    const email = userRecord.email;

    if (!email) {
      return {
        checkName: 'email_pattern',
        score: 0,
        flag: null,
        details: { error: 'Email not found' },
      };
    }

    // Check for Gmail alias pattern (user+something@gmail.com)
    const gmailAliasPattern = /^[^@]+\+[^@]+@gmail\.com$/i;
    const isAlias = gmailAliasPattern.test(email);

    if (isAlias) {
      return {
        checkName: 'email_pattern',
        score: 10,
        flag: 'gmail_alias_detected',
        details: { emailDomain: email.split('@')[1] },
      };
    }

    return {
      checkName: 'email_pattern',
      score: 0,
      flag: null,
      details: { emailDomain: email.split('@')[1] },
    };
  } catch (error) {
    console.error('Error in checkEmailPattern:', error);
    return {
      checkName: 'email_pattern',
      score: 0,
      flag: null,
      details: { error: String(error) },
    };
  }
}

