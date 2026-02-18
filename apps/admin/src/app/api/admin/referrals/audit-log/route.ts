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
    
    const limit = parseInt(searchParams.get('limit') || '50');
    const userId = searchParams.get('userId');
    const adminUid = searchParams.get('adminUid');
    const actionType = searchParams.get('actionType');

    let query = db.collection('referralAuditLog').orderBy('timestamp', 'desc');

    // Apply filters
    if (userId) {
      query = query.where('userId', '==', userId) as any;
    }

    if (adminUid) {
      query = query.where('performedBy', '==', adminUid) as any;
    }

    if (actionType) {
      query = query.where('actionType', '==', actionType) as any;
    }

    query = query.limit(limit) as any;

    const snapshot = await query.get();

    const logs = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate().toISOString() || null,
    }));

    return NextResponse.json(logs);
  } catch (error: any) {
    console.error('Error fetching audit log:', error);
    return NextResponse.json(
      { error: 'Failed to fetch audit log', details: error.message },
      { status: 500 }
    );
  }
}

