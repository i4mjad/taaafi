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
    const query = searchParams.get('q');
    const type = searchParams.get('type') || 'all'; // all, email, id, code

    if (!query || query.length < 2) {
      return NextResponse.json({ results: [] });
    }

    const results: any[] = [];
    const userIds = new Set<string>();

    // Search by user ID (exact match)
    if (type === 'all' || type === 'id') {
      const userDoc = await db.collection('users').doc(query).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        userIds.add(userDoc.id);
        
        // Get referral stats
        const statsDoc = await db.collection('referralStats').doc(userDoc.id).get();
        const verificationDoc = await db.collection('referralVerifications').doc(userDoc.id).get();
        
        results.push({
          userId: userDoc.id,
          displayName: userData?.displayName || 'N/A',
          email: userData?.email || 'N/A',
          photoURL: userData?.photoURL || null,
          createdAt: userData?.createdAt?.toDate?.()?.toISOString() || null,
          stats: statsDoc.exists ? statsDoc.data() : null,
          verification: verificationDoc.exists ? verificationDoc.data() : null,
          matchType: 'id',
        });
      }
    }

    // Search by email (case-insensitive partial match)
    if ((type === 'all' || type === 'email') && results.length < 20) {
      const emailQuery = query.toLowerCase();
      const usersSnapshot = await db.collection('users')
        .where('email', '>=', emailQuery)
        .where('email', '<=', emailQuery + '\uf8ff')
        .limit(10)
        .get();

      for (const userDoc of usersSnapshot.docs) {
        if (!userIds.has(userDoc.id)) {
          userIds.add(userDoc.id);
          const userData = userDoc.data();
          
          // Get referral stats
          const statsDoc = await db.collection('referralStats').doc(userDoc.id).get();
          const verificationDoc = await db.collection('referralVerifications').doc(userDoc.id).get();
          
          results.push({
            userId: userDoc.id,
            displayName: userData?.displayName || 'N/A',
            email: userData?.email || 'N/A',
            photoURL: userData?.photoURL || null,
            createdAt: userData?.createdAt?.toDate?.()?.toISOString() || null,
            stats: statsDoc.exists ? statsDoc.data() : null,
            verification: verificationDoc.exists ? verificationDoc.data() : null,
            matchType: 'email',
          });
        }
      }
    }

    // Search by referral code
    if ((type === 'all' || type === 'code') && results.length < 20) {
      const codeQuery = query.toUpperCase();
      const statsSnapshot = await db.collection('referralStats')
        .where('referralCode', '>=', codeQuery)
        .where('referralCode', '<=', codeQuery + '\uf8ff')
        .limit(10)
        .get();

      for (const statsDoc of statsSnapshot.docs) {
        if (!userIds.has(statsDoc.id)) {
          userIds.add(statsDoc.id);
          const statsData = statsDoc.data();
          
          // Get user data
          const userDoc = await db.collection('users').doc(statsDoc.id).get();
          const verificationDoc = await db.collection('referralVerifications').doc(statsDoc.id).get();
          
          if (userDoc.exists) {
            const userData = userDoc.data();
            results.push({
              userId: statsDoc.id,
              displayName: userData?.displayName || 'N/A',
              email: userData?.email || 'N/A',
              photoURL: userData?.photoURL || null,
              createdAt: userData?.createdAt?.toDate?.()?.toISOString() || null,
              stats: statsData,
              verification: verificationDoc.exists ? verificationDoc.data() : null,
              matchType: 'code',
            });
          }
        }
      }
    }

    // Sort results by creation date (newest first)
    results.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateB - dateA;
    });

    return NextResponse.json({
      success: true,
      count: results.length,
      results: results.slice(0, 20), // Limit to 20 results
    });
  } catch (error: any) {
    console.error('Error searching users:', error);
    return NextResponse.json(
      { error: 'Failed to search users', details: error.message },
      { status: 500 }
    );
  }
}

