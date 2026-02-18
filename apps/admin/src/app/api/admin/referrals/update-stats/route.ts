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
    const { userId, updates, reason, adminUid } = body;

    // Validation
    if (!userId) {
      return NextResponse.json({ error: 'userId is required' }, { status: 400 });
    }

    if (!updates || typeof updates !== 'object') {
      return NextResponse.json({ error: 'updates object is required' }, { status: 400 });
    }

    if (!reason || reason.trim() === '') {
      return NextResponse.json({ error: 'reason is required' }, { status: 400 });
    }

    // Allowed fields for manual update
    const allowedFields = [
      'totalReferred',
      'totalVerified',
      'totalPending',
      'totalBlocked',
      'totalRewardsEarned',
    ];

    // Filter out non-allowed fields
    const filteredUpdates: any = {};
    for (const key of Object.keys(updates)) {
      if (allowedFields.includes(key)) {
        filteredUpdates[key] = updates[key];
      }
    }

    if (Object.keys(filteredUpdates).length === 0) {
      return NextResponse.json(
        { error: 'No valid fields to update. Allowed fields: ' + allowedFields.join(', ') },
        { status: 400 }
      );
    }

    // Get current stats
    const statsRef = db.collection('referralStats').doc(userId);
    const statsDoc = await statsRef.get();

    const previousStats = statsDoc.exists ? statsDoc.data() : {};

    // Update stats
    await statsRef.set(
      {
        ...filteredUpdates,
        lastUpdatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Log the update in audit trail
    await db.collection('referralAuditLog').add({
      userId,
      actionType: 'update_stats',
      performedBy: adminUid || 'admin',
      timestamp: FieldValue.serverTimestamp(),
      details: {
        reason,
        previousStats: previousStats,
        updates: filteredUpdates,
      },
    });

    // Get updated stats
    const updatedStatsDoc = await statsRef.get();
    const newStats = updatedStatsDoc.data();

    return NextResponse.json({
      success: true,
      userId,
      previousStats,
      newStats,
      updatedFields: Object.keys(filteredUpdates),
    });
  } catch (error: any) {
    console.error('Error updating stats:', error);
    return NextResponse.json(
      { error: 'Failed to update stats', details: error.message },
      { status: 500 }
    );
  }
}

