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

function getWeekNumber(date: Date): string {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000;
  const weekNumber = Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
  return `${date.getFullYear()}-W${weekNumber.toString().padStart(2, '0')}`;
}

function getMonthKey(date: Date): string {
  return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`;
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
    
    const groupBy = searchParams.get('groupBy') || 'week'; // 'week' or 'month'
    const limit = parseInt(searchParams.get('limit') || '12');

    // Fetch all referral verifications
    const verificationsSnapshot = await db.collection('referralVerifications')
      .orderBy('createdAt', 'desc')
      .limit(1000) // Limit to prevent excessive data
      .get();

    // Group by cohort
    const cohorts: { [key: string]: any } = {};

    verificationsSnapshot.forEach((doc) => {
      const data = doc.data();
      const createdAt = data.createdAt?.toDate();

      if (!createdAt) return;

      const cohortKey = groupBy === 'month' ? getMonthKey(createdAt) : getWeekNumber(createdAt);

      if (!cohorts[cohortKey]) {
        cohorts[cohortKey] = {
          cohortKey,
          totalSignups: 0,
          totalVerified: 0,
          totalBlocked: 0,
          totalPending: 0,
          avgTimeToVerify: 0,
          verificationTimes: [],
        };
      }

      cohorts[cohortKey].totalSignups++;

      if (data.verificationStatus === 'verified') {
        cohorts[cohortKey].totalVerified++;

        // Calculate time to verify (in days)
        if (data.verifiedAt) {
          const verifiedAt = data.verifiedAt.toDate();
          const timeToVerify = (verifiedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
          cohorts[cohortKey].verificationTimes.push(timeToVerify);
        }
      } else if (data.verificationStatus === 'pending') {
        cohorts[cohortKey].totalPending++;
      }

      if (data.isBlocked) {
        cohorts[cohortKey].totalBlocked++;
      }
    });

    // Calculate averages and conversion rates
    const cohortData = Object.values(cohorts).map((cohort: any) => {
      const avgTimeToVerify = cohort.verificationTimes.length > 0
        ? cohort.verificationTimes.reduce((a: number, b: number) => a + b, 0) / cohort.verificationTimes.length
        : 0;

      const conversionRate = cohort.totalSignups > 0
        ? (cohort.totalVerified / cohort.totalSignups) * 100
        : 0;

      return {
        cohortKey: cohort.cohortKey,
        totalSignups: cohort.totalSignups,
        totalVerified: cohort.totalVerified,
        totalBlocked: cohort.totalBlocked,
        totalPending: cohort.totalPending,
        conversionRate: Math.round(conversionRate * 100) / 100,
        avgTimeToVerify: Math.round(avgTimeToVerify * 10) / 10,
      };
    });

    // Sort by cohort key (most recent first)
    cohortData.sort((a, b) => b.cohortKey.localeCompare(a.cohortKey));

    // Limit results
    const limitedData = cohortData.slice(0, limit);

    return NextResponse.json({
      groupBy,
      cohorts: limitedData,
    });
  } catch (error: any) {
    console.error('Error fetching cohort analysis:', error);
    return NextResponse.json(
      { error: 'Failed to fetch cohort analysis', details: error.message },
      { status: 500 }
    );
  }
}

