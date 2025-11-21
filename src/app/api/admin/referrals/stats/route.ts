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
    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const db = getFirestore();

    // Fetch aggregate stats from referralVerifications collection
    const verificationsSnapshot = await db.collection('referralVerifications').get();
    const allVerifications = verificationsSnapshot.docs;

    // Calculate basic stats
    const totalReferrals = allVerifications.length;
    const totalVerified = allVerifications.filter(d => d.data().verificationStatus === 'verified').length;
    const totalPending = allVerifications.filter(d => d.data().verificationStatus === 'pending').length;
    const totalBlocked = allVerifications.filter(d => d.data().verificationStatus === 'blocked').length;

    // Fraud stats
    const flaggedForReview = allVerifications.filter(d => {
      const fraudScore = d.data().fraudScore || 0;
      return fraudScore >= 40 && fraudScore < 71;
    }).length;

    const autoBlocked = allVerifications.filter(d => {
      const fraudScore = d.data().fraudScore || 0;
      return fraudScore >= 71;
    }).length;

    // Get total rewards distributed
    const rewardsSnapshot = await db.collection('referralRewards').get();
    const totalRewardsDistributed = rewardsSnapshot.docs.reduce((sum, doc) => {
      const data = doc.data();
      return sum + (data.rewardDays || 0);
    }, 0);

    // Calculate conversion rate
    const conversionRate = totalReferrals > 0 
      ? ((totalVerified / totalReferrals) * 100).toFixed(2) 
      : '0.00';

    const stats = {
      totalReferrals,
      totalVerified,
      totalPending,
      totalBlocked,
      flaggedForReview,
      autoBlocked,
      totalRewardsDistributed,
      conversionRate: parseFloat(conversionRate),
    };

    return NextResponse.json(stats);
  } catch (error: any) {
    console.error('Error fetching referral stats:', error);
    return NextResponse.json(
      { error: 'Failed to fetch referral stats', details: error.message },
      { status: 500 }
    );
  }
}

