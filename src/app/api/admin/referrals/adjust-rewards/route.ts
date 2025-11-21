import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

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

export async function POST(request: NextRequest) {
  try {
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const db = getFirestore();
    const body = await request.json();
    const { userId, adjustmentDays, reason, adminUid } = body;

    // Validation
    if (!userId) {
      return NextResponse.json({ error: 'userId is required' }, { status: 400 });
    }

    if (adjustmentDays === undefined || adjustmentDays === null) {
      return NextResponse.json({ error: 'adjustmentDays is required' }, { status: 400 });
    }

    if (!reason || reason.trim() === '') {
      return NextResponse.json({ error: 'reason is required' }, { status: 400 });
    }

    // Check if user exists
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Get current referral stats
    const statsRef = db.collection('referralStats').doc(userId);
    const statsDoc = await statsRef.get();

    const currentRewards = statsDoc.exists ? (statsDoc.data()?.totalRewardsEarned || 0) : 0;
    const newRewards = currentRewards + adjustmentDays;

    // Update referral stats
    await statsRef.set(
      {
        totalRewardsEarned: newRewards >= 0 ? newRewards : 0, // Prevent negative
        lastUpdatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Log the adjustment in audit trail
    await db.collection('referralAuditLog').add({
      userId,
      actionType: 'adjust_rewards',
      performedBy: adminUid || 'admin',
      timestamp: FieldValue.serverTimestamp(),
      details: {
        adjustmentDays,
        previousRewards: currentRewards,
        newRewards: newRewards >= 0 ? newRewards : 0,
        reason,
      },
    });

    return NextResponse.json({
      success: true,
      userId,
      previousRewards: currentRewards,
      newRewards: newRewards >= 0 ? newRewards : 0,
      adjustmentDays,
    });
  } catch (error: any) {
    console.error('Error adjusting rewards:', error);
    return NextResponse.json(
      { error: 'Failed to adjust rewards', details: error.message },
      { status: 500 }
    );
  }
}

