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
    const searchParams = request.nextUrl.searchParams;
    const limit = parseInt(searchParams.get('limit') || '20');

    // Fetch recent verifications
    const verificationsSnapshot = await db
      .collection('referralVerifications')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const activities = await Promise.all(
      verificationsSnapshot.docs.map(async (doc) => {
        const data = doc.data();
        const status = data.verificationStatus;
        const fraudScore = data.fraudScore || 0;
        
        // Get user display name
        let userName = 'Unknown User';
        try {
          const userDoc = await db.collection('users').doc(data.referredUserId).get();
          if (userDoc.exists) {
            userName = userDoc.data()?.displayName || userName;
          }
        } catch (error) {
          // Silent fail
        }

        // Determine activity type and message
        let type: 'signup' | 'verified' | 'reward' | 'blocked';
        let message: string;

        if (status === 'blocked' || fraudScore >= 71) {
          type = 'blocked';
          message = `User ${userName} was blocked due to fraud detection (score: ${fraudScore})`;
        } else if (status === 'verified') {
          type = 'verified';
          message = `User ${userName} completed verification successfully`;
        } else if (status === 'pending') {
          type = 'signup';
          message = `New referral signup: ${userName}`;
        } else {
          type = 'signup';
          message = `Referral activity for ${userName}`;
        }

        return {
          id: doc.id,
          type,
          message,
          timestamp: data.createdAt?.toDate() || new Date(),
          userId: data.referredUserId,
        };
      })
    );

    return NextResponse.json(activities);
  } catch (error: any) {
    console.error('Error fetching recent activity:', error);
    return NextResponse.json(
      { error: 'Failed to fetch recent activity', details: error.message },
      { status: 500 }
    );
  }
}

