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

    // Clear fraud flags and reset fraud score
    await verificationRef.update({
      fraudScore: 0,
      fraudFlags: [],
      isBlocked: false,
      blockedReason: null,
      blockedAt: null,
      fraudOverride: true,
      fraudOverrideReason: reason,
      fraudOverrideBy: adminUid || 'admin',
      fraudOverrideAt: FieldValue.serverTimestamp(),
      lastCheckedAt: FieldValue.serverTimestamp(),
    });

    // Log the override action in audit trail
    await db.collection('referralAuditLog').add({
      userId,
      actionType: 'override_fraud',
      performedBy: adminUid || 'admin',
      timestamp: FieldValue.serverTimestamp(),
      details: {
        reason,
        previousFraudScore: previousData?.fraudScore || 0,
        previousFraudFlags: previousData?.fraudFlags || [],
        previousIsBlocked: previousData?.isBlocked || false,
      },
    });

    // Log in fraud logs as well
    await db.collection('referralFraudLogs').add({
      userId,
      action: 'override',
      fraudScore: previousData?.fraudScore || 0,
      fraudFlags: previousData?.fraudFlags || [],
      reason,
      performedBy: adminUid || 'admin',
      timestamp: FieldValue.serverTimestamp(),
      details: {
        override: true,
        previousStatus: previousData?.verificationStatus,
        referrerId: previousData?.referrerId,
      },
    });

    return NextResponse.json({
      success: true,
      userId,
      previousFraudScore: previousData?.fraudScore || 0,
      newFraudScore: 0,
      clearedFlags: previousData?.fraudFlags || [],
    });
  } catch (error: any) {
    console.error('Error overriding fraud:', error);
    return NextResponse.json(
      { error: 'Failed to override fraud', details: error.message },
      { status: 500 }
    );
  }
}

