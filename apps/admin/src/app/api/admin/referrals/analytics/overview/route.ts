import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

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
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const db = getFirestore();
    const { searchParams } = new URL(request.url);
    
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    // Parse dates
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    // Fetch referral verifications within date range
    const verificationsQuery = db.collection('referralVerifications')
      .where('createdAt', '>=', start)
      .where('createdAt', '<=', end);

    const verificationsSnapshot = await verificationsQuery.get();

    // Calculate metrics
    let totalReferrals = 0;
    let totalVerified = 0;
    let totalPending = 0;
    let totalBlocked = 0;
    let totalFraudFlagged = 0;
    let totalRewards = 0;
    let fraudScoreSum = 0;

    verificationsSnapshot.forEach((doc) => {
      const data = doc.data();
      totalReferrals++;

      if (data.verificationStatus === 'verified') {
        totalVerified++;
      } else if (data.verificationStatus === 'pending') {
        totalPending++;
      }

      if (data.isBlocked) {
        totalBlocked++;
      }

      if ((data.fraudFlags || []).length > 0) {
        totalFraudFlagged++;
      }

      fraudScoreSum += data.fraudScore || 0;
    });

    // Fetch total rewards distributed
    const statsSnapshot = await db.collection('referralStats').get();
    statsSnapshot.forEach((doc) => {
      const data = doc.data();
      totalRewards += data.totalRewardsEarned || 0;
    });

    // Calculate conversion rate
    const conversionRate = totalReferrals > 0 ? (totalVerified / totalReferrals) * 100 : 0;

    // Calculate average fraud score
    const avgFraudScore = totalReferrals > 0 ? fraudScoreSum / totalReferrals : 0;

    // Fetch top referrers (top 10)
    const topReferrersQuery = db.collection('referralStats')
      .orderBy('totalVerified', 'desc')
      .limit(10);

    const topReferrersSnapshot = await topReferrersQuery.get();
    const topReferrers: any[] = [];

    for (const doc of topReferrersSnapshot.docs) {
      const data = doc.data();
      const userDoc = await db.collection('users').doc(doc.id).get();
      const userData = userDoc.data();

      topReferrers.push({
        userId: doc.id,
        displayName: userData?.displayName || 'Unknown',
        email: userData?.email || '',
        totalVerified: data.totalVerified || 0,
        totalReferred: data.totalReferred || 0,
        totalRewards: data.totalRewardsEarned || 0,
      });
    }

    return NextResponse.json({
      dateRange: {
        start: start.toISOString(),
        end: end.toISOString(),
      },
      totalReferrals,
      totalVerified,
      totalPending,
      totalBlocked,
      totalFraudFlagged,
      conversionRate: Math.round(conversionRate * 100) / 100,
      avgFraudScore: Math.round(avgFraudScore * 100) / 100,
      totalRewardsDistributed: totalRewards,
      topReferrers,
    });
  } catch (error: any) {
    console.error('Error fetching analytics overview:', error);
    return NextResponse.json(
      { error: 'Failed to fetch analytics overview', details: error.message },
      { status: 500 }
    );
  }
}

