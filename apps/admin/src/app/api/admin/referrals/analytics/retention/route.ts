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

    // Fetch all verifications
    const verificationsSnapshot = await db.collection('referralVerifications')
      .orderBy('createdAt', 'desc')
      .limit(1000)
      .get();

    // Calculate retention metrics
    let totalUsers = 0;
    let within7Days = 0;
    let within14Days = 0;
    let within30Days = 0;
    let over30Days = 0;
    let neverCompleted = 0;

    const now = new Date();

    verificationsSnapshot.forEach((doc) => {
      const data = doc.data();
      totalUsers++;

      const createdAt = data.createdAt?.toDate();
      const verifiedAt = data.verifiedAt?.toDate();

      if (data.verificationStatus === 'verified' && createdAt && verifiedAt) {
        const daysToVerify = (verifiedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24);

        if (daysToVerify <= 7) {
          within7Days++;
        } else if (daysToVerify <= 14) {
          within14Days++;
        } else if (daysToVerify <= 30) {
          within30Days++;
        } else {
          over30Days++;
        }
      } else if (data.verificationStatus !== 'verified') {
        // Check if they've been pending for more than 30 days
        const daysSinceSignup = (now.getTime() - (createdAt?.getTime() || now.getTime())) / (1000 * 60 * 60 * 24);
        if (daysSinceSignup > 30) {
          neverCompleted++;
        }
      }
    });

    // Calculate retention rate
    const verifiedUsers = within7Days + within14Days + within30Days + over30Days;
    const retentionRate = totalUsers > 0 ? (verifiedUsers / totalUsers) * 100 : 0;

    return NextResponse.json({
      totalUsers,
      verifiedUsers,
      retentionRate: Math.round(retentionRate * 100) / 100,
      breakdown: {
        within7Days,
        within14Days,
        within30Days,
        over30Days,
        neverCompleted,
      },
      percentages: {
        within7Days: totalUsers > 0 ? Math.round((within7Days / totalUsers) * 100 * 100) / 100 : 0,
        within14Days: totalUsers > 0 ? Math.round((within14Days / totalUsers) * 100 * 100) / 100 : 0,
        within30Days: totalUsers > 0 ? Math.round((within30Days / totalUsers) * 100 * 100) / 100 : 0,
        over30Days: totalUsers > 0 ? Math.round((over30Days / totalUsers) * 100 * 100) / 100 : 0,
        neverCompleted: totalUsers > 0 ? Math.round((neverCompleted / totalUsers) * 100 * 100) / 100 : 0,
      },
    });
  } catch (error: any) {
    console.error('Error fetching retention analysis:', error);
    return NextResponse.json(
      { error: 'Failed to fetch retention analysis', details: error.message },
      { status: 500 }
    );
  }
}

