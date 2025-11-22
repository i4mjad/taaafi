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
    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const db = getFirestore();
    const body = await request.json();
    const { userIds, adminUid, reason } = body;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return NextResponse.json(
        { error: 'userIds array is required' },
        { status: 400 }
      );
    }

    if (!reason || typeof reason !== 'string' || reason.trim().length === 0) {
      return NextResponse.json(
        { error: 'reason is required' },
        { status: 400 }
      );
    }

    // Process each user block
    const results = await Promise.allSettled(
      userIds.map(async (userId: string) => {
        const verificationRef = db.collection('referralVerifications').doc(userId);
        const verificationDoc = await verificationRef.get();

        if (!verificationDoc.exists) {
          throw new Error(`Verification document not found for user ${userId}`);
        }

        const verificationData = verificationDoc.data();

        // Update verification document
        await verificationRef.update({
          isBlocked: true,
          blockedReason: reason,
          blockedAt: FieldValue.serverTimestamp(),
          verificationStatus: 'blocked',
          lastCheckedAt: FieldValue.serverTimestamp(),
        });

        // Log the block action to fraud logs
        await db.collection('referralFraudLogs').add({
          userId,
          action: 'manual_block',
          fraudScore: verificationData?.fraudScore || 0,
          fraudFlags: verificationData?.fraudFlags || [],
          reason: reason,
          performedBy: adminUid || 'admin',
          timestamp: FieldValue.serverTimestamp(),
          details: {
            previousStatus: verificationData?.verificationStatus,
            referrerId: verificationData?.referrerId,
          },
        });

        // Update referrer stats
        if (verificationData?.referrerId) {
          const referrerStatsRef = db.collection('referralStats').doc(verificationData.referrerId);
          const referrerStatsDoc = await referrerStatsRef.get();

          if (referrerStatsDoc.exists) {
            await referrerStatsRef.update({
              blockedReferrals: FieldValue.increment(1),
            });
          }
        }

        return { userId, success: true };
      })
    );

    // Collect successes and failures
    const successes = results.filter((r) => r.status === 'fulfilled').map((r: any) => r.value);
    const failures = results
      .filter((r) => r.status === 'rejected')
      .map((r: any) => ({ error: r.reason.message }));

    return NextResponse.json({
      success: true,
      blocked: successes.length,
      failed: failures.length,
      results: { successes, failures },
    });
  } catch (error: any) {
    console.error('Error blocking users:', error);
    return NextResponse.json(
      { error: 'Failed to block users', details: error.message },
      { status: 500 }
    );
  }
}

