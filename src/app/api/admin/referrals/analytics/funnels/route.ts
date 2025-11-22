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
    const verificationsSnapshot = await db.collection('referralVerifications')
      .where('createdAt', '>=', start)
      .where('createdAt', '<=', end)
      .get();

    // Initialize funnel stages
    const funnel = {
      signups: 0,
      checklistStarted: 0,
      partiallyCompleted: 0,
      fullyCompleted: 0,
      verified: 0,
      blocked: 0,
    };

    verificationsSnapshot.forEach((doc) => {
      const data = doc.data();
      funnel.signups++;

      // Check if checklist started (any task completed)
      const checklist = data.checklist || {};
      const tasksCompleted = [
        checklist.accountAge?.completed,
        checklist.forumPosts?.completed,
        checklist.interactions?.completed,
        checklist.groupActivity?.completed,
        checklist.recoveryActivity?.completed,
      ].filter(Boolean).length;

      if (tasksCompleted > 0) {
        funnel.checklistStarted++;
      }

      if (tasksCompleted >= 1 && tasksCompleted < 5) {
        funnel.partiallyCompleted++;
      }

      if (tasksCompleted === 5) {
        funnel.fullyCompleted++;
      }

      if (data.verificationStatus === 'verified') {
        funnel.verified++;
      }

      if (data.isBlocked) {
        funnel.blocked++;
      }
    });

    // Calculate conversion rates and drop-offs
    const signups = funnel.signups || 1; // Prevent division by zero

    const funnelData = [
      {
        stage: 'signups',
        count: funnel.signups,
        percentage: 100,
        dropOff: 0,
      },
      {
        stage: 'checklistStarted',
        count: funnel.checklistStarted,
        percentage: Math.round((funnel.checklistStarted / signups) * 100 * 100) / 100,
        dropOff: funnel.signups - funnel.checklistStarted,
      },
      {
        stage: 'partiallyCompleted',
        count: funnel.partiallyCompleted,
        percentage: Math.round((funnel.partiallyCompleted / signups) * 100 * 100) / 100,
        dropOff: funnel.checklistStarted - funnel.partiallyCompleted,
      },
      {
        stage: 'fullyCompleted',
        count: funnel.fullyCompleted,
        percentage: Math.round((funnel.fullyCompleted / signups) * 100 * 100) / 100,
        dropOff: funnel.partiallyCompleted - funnel.fullyCompleted,
      },
      {
        stage: 'verified',
        count: funnel.verified,
        percentage: Math.round((funnel.verified / signups) * 100 * 100) / 100,
        dropOff: funnel.fullyCompleted - funnel.verified,
      },
    ];

    return NextResponse.json({
      dateRange: {
        start: start.toISOString(),
        end: end.toISOString(),
      },
      funnel: funnelData,
      blocked: funnel.blocked,
    });
  } catch (error: any) {
    console.error('Error fetching funnel analysis:', error);
    return NextResponse.json(
      { error: 'Failed to fetch funnel analysis', details: error.message },
      { status: 500 }
    );
  }
}

