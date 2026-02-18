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
    const { userId, reason, adminUid } = body;

    // Validation
    if (!userId) {
      return NextResponse.json({ error: 'userId is required' }, { status: 400 });
    }

    if (!reason || reason.trim() === '') {
      return NextResponse.json({ error: 'reason is required' }, { status: 400 });
    }

    // Check if verification document exists
    const verificationRef = db.collection('referralVerifications').doc(userId);
    const verificationDoc = await verificationRef.get();

    if (!verificationDoc.exists) {
      return NextResponse.json({ error: 'Verification document not found' }, { status: 404 });
    }

    const previousData = verificationDoc.data();

    // Reset verification checklist to initial state
    await verificationRef.update({
      verificationStatus: 'pending',
      checklist: {
        accountAge: { completed: false, completedAt: null },
        forumPosts: { count: 0, target: 3, completed: false, completedAt: null },
        interactions: { count: 0, target: 5, completed: false, completedAt: null },
        groupActivity: { count: 0, target: 3, completed: false, completedAt: null },
        recoveryActivity: { completed: false, completedAt: null },
      },
      isBlocked: false,
      blockedReason: null,
      blockedAt: null,
      verifiedAt: null,
      lastCheckedAt: FieldValue.serverTimestamp(),
    });

    // Log the reset action in audit trail
    await db.collection('referralAuditLog').add({
      userId,
      actionType: 'reset_verification',
      performedBy: adminUid || 'admin',
      timestamp: FieldValue.serverTimestamp(),
      details: {
        reason,
        previousStatus: previousData?.verificationStatus,
        previousChecklist: previousData?.checklist,
        referrerId: previousData?.referrerId,
      },
    });

    // Update referrer stats if necessary
    if (previousData?.referrerId && previousData?.verificationStatus === 'verified') {
      const referrerStatsRef = db.collection('referralStats').doc(previousData.referrerId);
      await referrerStatsRef.update({
        totalVerified: FieldValue.increment(-1),
      });
    }

    return NextResponse.json({
      success: true,
      userId,
      previousStatus: previousData?.verificationStatus,
      newStatus: 'pending',
    });
  } catch (error: any) {
    console.error('Error resetting verification:', error);
    return NextResponse.json(
      { error: 'Failed to reset verification', details: error.message },
      { status: 500 }
    );
  }
}

