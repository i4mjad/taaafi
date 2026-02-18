import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

// Initialize Firebase Admin SDK
if (!getApps().length) {
  const serviceAccount = {
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
    privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
  };

  if (!serviceAccount.projectId || !serviceAccount.privateKey || !serviceAccount.clientEmail) {
    console.warn('Firebase Admin SDK credentials not found in environment variables');
  } else {
    initializeApp({
      credential: cert(serviceAccount),
    });
  }
}

export async function GET(request: NextRequest) {
  try {
    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const db = getFirestore();
    const auth = getAuth();
    const searchParams = request.nextUrl.searchParams;
    const limit = parseInt(searchParams.get('limit') || '10');

    // First, get all users who have referral codes
    const referralCodesSnapshot = await db
      .collection('referralCodes')
      .get();

    const userIdsWithCodes = new Set(
      referralCodesSnapshot.docs.map(doc => doc.data().userId)
    );

    // Fetch top referrers from referralStats collection
    // Only get users with actual referrals (totalReferred > 0)
    const statsSnapshot = await db
      .collection('referralStats')
      .where('totalReferred', '>', 0)
      .orderBy('totalReferred', 'desc')
      .orderBy('totalVerified', 'desc')
      .limit(limit * 3) // Fetch more to filter
      .get();

    // Filter stats to only users with referral codes AND who have referrals
    const filteredStats = statsSnapshot.docs
      .filter(doc => {
        const data = doc.data();
        return userIdsWithCodes.has(doc.id) && (data.totalReferred || 0) > 0;
      })
      .slice(0, limit); // Take only the requested limit after filtering

    // Fetch user details for each referrer
    const topReferrers = await Promise.all(
      filteredStats.map(async (doc) => {
        const data = doc.data();
        const userId = doc.id;
        
        // Get user details from Firestore first
        let displayName = 'Unknown User';
        let email = '';
        let photoURL = null;

        try {
          const userDoc = await db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            displayName = userData?.displayName || displayName;
            email = userData?.email || email;
            photoURL = userData?.photoURL || null;
          }
        } catch (error) {
          console.warn(`Could not fetch Firestore data for user ${userId}`);
        }

        // If email not found in Firestore, try Auth
        if (!email) {
          try {
            const userRecord = await auth.getUser(userId);
            email = userRecord.email || '';
            if (!displayName || displayName === 'Unknown User') {
              displayName = userRecord.displayName || email || userId.substring(0, 8);
            }
          } catch (error) {
            console.warn(`Could not fetch auth data for user ${userId}`);
          }
        }

        // Calculate total rewards
        const totalRewardDays = data.totalRewardDays || 0;
        const totalRewards = totalRewardDays > 0 
          ? `${totalRewardDays} days` 
          : 'No rewards';

        return {
          userId,
          displayName,
          email,
          photoURL,
          totalReferred: data.totalReferred || 0,
          totalVerified: data.totalVerified || 0,
          totalRewards,
        };
      })
    );

    return NextResponse.json(topReferrers);
  } catch (error: any) {
    console.error('Error fetching top referrers:', error);
    return NextResponse.json(
      { error: 'Failed to fetch top referrers', details: error.message },
      { status: 500 }
    );
  }
}

