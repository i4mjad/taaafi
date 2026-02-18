import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

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
    const days = parseInt(searchParams.get('days') || '30');

    // Calculate date range
    const now = new Date();
    const startDate = new Date(now);
    startDate.setDate(startDate.getDate() - days);

    // Fetch referrals within date range
    const verificationsSnapshot = await db
      .collection('referralVerifications')
      .where('createdAt', '>=', Timestamp.fromDate(startDate))
      .orderBy('createdAt', 'asc')
      .get();

    // Group by date
    const dataByDate = new Map<string, { referrals: number; verified: number }>();

    // Initialize all dates in range with zero values
    for (let i = 0; i < days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateKey = date.toISOString().split('T')[0];
      dataByDate.set(dateKey, { referrals: 0, verified: 0 });
    }

    // Count referrals by date
    verificationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const createdAt = data.createdAt?.toDate();
      if (createdAt) {
        const dateKey = createdAt.toISOString().split('T')[0];
        const existing = dataByDate.get(dateKey) || { referrals: 0, verified: 0 };
        existing.referrals++;
        if (data.verificationStatus === 'verified') {
          existing.verified++;
        }
        dataByDate.set(dateKey, existing);
      }
    });

    // Convert to array format for chart
    const chartData = Array.from(dataByDate.entries())
      .map(([date, counts]) => ({
        date,
        referrals: counts.referrals,
        verified: counts.verified,
      }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return NextResponse.json(chartData);
  } catch (error: any) {
    console.error('Error fetching chart data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch chart data', details: error.message },
      { status: 500 }
    );
  }
}

