// functions/src/referral/fraud/patternDetection.ts
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Detects if multiple referred users show identical or coordinated patterns
 * This is useful for detecting when one person creates multiple fake accounts
 */
export async function detectCoordinatedFraud(referrerId: string): Promise<boolean> {
  try {
    // Get all referrals for this referrer
    const referralsQuery = await db
      .collection('referralVerifications')
      .where('referrerId', '==', referrerId)
      .where('verificationStatus', '==', 'pending')
      .get();

    if (referralsQuery.size < 2) {
      return false; // Need at least 2 referrals to detect coordination
    }

    const referralUserIds = referralsQuery.docs.map((doc) => doc.id);

    // Get user documents for all referrals
    const userDocs = await Promise.all(
      referralUserIds.map((userId) => db.collection('users').doc(userId).get())
    );

    // Check 1: Same device IDs across multiple referrals
    const allDeviceIds: string[][] = [];
    userDocs.forEach((doc) => {
      if (doc.exists) {
        const devices = (doc.data()?.devicesIds || []) as string[];
        allDeviceIds.push(devices);
      }
    });

    // Check if any devices are shared between referrals
    for (let i = 0; i < allDeviceIds.length; i++) {
      for (let j = i + 1; j < allDeviceIds.length; j++) {
        const overlap = allDeviceIds[i].some((device) =>
          allDeviceIds[j].includes(device)
        );
        if (overlap) {
          console.log(
            `⚠️ Coordinated fraud detected: Shared devices between referrals of ${referrerId}`
          );
          return true;
        }
      }
    }

    // Check 2: Sequential email addresses (user1@, user2@, user3@)
    const emails: string[] = [];
    for (const userId of referralUserIds) {
      try {
        const userRecord = await admin.auth().getUser(userId);
        if (userRecord.email) {
          emails.push(userRecord.email);
        }
      } catch (error) {
        // Skip if user not found
      }
    }

    // Check for sequential patterns in emails
    const emailPrefixes = emails.map((email) => email.split('@')[0].toLowerCase());
    const hasSequentialPattern = emailPrefixes.some((prefix, index) => {
      if (index === 0) return false;
      const prevPrefix = emailPrefixes[index - 1];
      
      // Check if prefixes are similar with just a number difference
      const currentWithoutNumbers = prefix.replace(/\d+/g, '');
      const prevWithoutNumbers = prevPrefix.replace(/\d+/g, '');
      
      return currentWithoutNumbers === prevWithoutNumbers;
    });

    if (hasSequentialPattern) {
      console.log(
        `⚠️ Coordinated fraud detected: Sequential email pattern for ${referrerId}`
      );
      return true;
    }

    // Check 3: Very similar posting times
    const postingTimes: number[][] = []; // Array of arrays of timestamps

    for (const userId of referralUserIds) {
      // Get CP ID
      const cpQuery = await db
        .collection('communityProfiles')
        .where('userUID', '==', userId)
        .limit(1)
        .get();

      if (!cpQuery.empty) {
        const cpId = cpQuery.docs[0].id;

        // Get posting times
        const postsQuery = await db
          .collection('forumPosts')
          .where('authorCPId', '==', cpId)
          .orderBy('createdAt', 'asc')
          .get();

        const times: number[] = [];
        postsQuery.forEach((doc) => {
          const createdAt = doc.data().createdAt;
          if (createdAt) {
            times.push(createdAt.toMillis());
          }
        });

        if (times.length > 0) {
          postingTimes.push(times);
        }
      }
    }

    // Check if posting times are suspiciously similar (within 5 minutes)
    if (postingTimes.length >= 2) {
      for (let i = 0; i < postingTimes.length; i++) {
        for (let j = i + 1; j < postingTimes.length; j++) {
          const times1 = postingTimes[i];
          const times2 = postingTimes[j];

          // Check if they have similar patterns
          const minLength = Math.min(times1.length, times2.length);
          if (minLength === 0) continue;

          let similarityCount = 0;
          for (let k = 0; k < minLength; k++) {
            const diffMinutes = Math.abs(times1[k] - times2[k]) / (1000 * 60);
            if (diffMinutes < 5) {
              similarityCount++;
            }
          }

          // If more than 50% of posts are within 5 minutes of each other
          if (similarityCount / minLength > 0.5) {
            console.log(
              `⚠️ Coordinated fraud detected: Similar posting times for ${referrerId}`
            );
            return true;
          }
        }
      }
    }

    return false;
  } catch (error) {
    console.error('Error detecting coordinated fraud:', error);
    return false;
  }
}

/**
 * Checks if a user's activity matches known fraud templates
 * Fraudsters often follow predictable patterns
 */
export async function matchesFraudTemplate(userId: string): Promise<boolean> {
  try {
    // Get verification document
    const verificationDoc = await db
      .collection('referralVerifications')
      .doc(userId)
      .get();

    if (!verificationDoc.exists) {
      return false;
    }

    const checklist = verificationDoc.data()?.checklist;

    // Template 1: Exactly minimum requirements with no variation
    // (exactly 3 posts, 5 interactions, 3 messages - nothing more)
    const postsCount = checklist?.forumPosts3?.current || 0;
    const interactionsCount = checklist?.interactions5?.current || 0;
    const messagesCount = checklist?.groupMessages3?.current || 0;

    if (postsCount === 3 && interactionsCount === 5 && messagesCount === 3) {
      // Check if all completed around the same time
      const completedTimes: number[] = [];

      if (checklist?.forumPosts3?.completedAt) {
        completedTimes.push(checklist.forumPosts3.completedAt.toMillis());
      }
      if (checklist?.interactions5?.completedAt) {
        completedTimes.push(checklist.interactions5.completedAt.toMillis());
      }
      if (checklist?.groupMessages3?.completedAt) {
        completedTimes.push(checklist.groupMessages3.completedAt.toMillis());
      }

      if (completedTimes.length >= 3) {
        const maxTime = Math.max(...completedTimes);
        const minTime = Math.min(...completedTimes);
        const timeSpanHours = (maxTime - minTime) / (1000 * 60 * 60);

        // If all completed within 1 hour
        if (timeSpanHours < 1) {
          console.log(
            `⚠️ Fraud template match: Exact minimums completed within 1 hour for ${userId}`
          );
          return true;
        }
      }
    }

    // Template 2: Very low content quality across all posts
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    const cpQuery = await db
      .collection('communityProfiles')
      .where('userUID', '==', userId)
      .limit(1)
      .get();

    if (cpQuery.empty) return false;

    const cpId = cpQuery.docs[0].id;

    // Get all forum posts
    const postsQuery = await db
      .collection('forumPosts')
      .where('authorCPId', '==', cpId)
      .get();

    if (postsQuery.size >= 3) {
      let allShort = true;
      postsQuery.forEach((doc) => {
        const body = doc.data().body || '';
        const words = body.trim().split(/\s+/).length;
        if (words > 15) {
          // More than 15 words = not suspicious
          allShort = false;
        }
      });

      if (allShort && postsQuery.size === 3) {
        console.log(
          `⚠️ Fraud template match: All posts very short for ${userId}`
        );
        return true;
      }
    }

    // Template 3: No activity variation
    // Check if user only does exactly what's required (no extra interactions, no browsing)
    // This is harder to detect, so we'll use other signals

    return false;
  } catch (error) {
    console.error('Error checking fraud template:', error);
    return false;
  }
}

/**
 * Runs both pattern detection checks and returns a combined result
 */
export async function runPatternDetection(
  userId: string,
  referrerId: string
): Promise<{ isCoordinated: boolean; matchesTemplate: boolean }> {
  const [isCoordinated, matchesTemplate] = await Promise.all([
    detectCoordinatedFraud(referrerId),
    matchesFraudTemplate(userId),
  ]);

  return { isCoordinated, matchesTemplate };
}

