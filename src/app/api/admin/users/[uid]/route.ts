import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
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

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ uid: string }> }
): Promise<NextResponse> {
  try {
    const { uid } = await context.params;

    const auth = getAuth();
    const firestore = getFirestore();

    // Get user from Firebase Auth
    const authUser = await auth.getUser(uid);

    // Get additional user data from Firestore (if exists)
    let firestoreProfile: any = {};
    try {
      const userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        firestoreProfile = userDoc.data() || {};
      }
    } catch (firestoreError) {
      console.warn(`Could not fetch Firestore profile for user ${uid}:`, firestoreError);
    }

    const customClaims = authUser.customClaims || {};
    
    // Transform to our UserProfile format
    const userProfile = {
      uid: authUser.uid,
      email: authUser.email || '',
      displayName: authUser.displayName || firestoreProfile.displayName || null,
      photoURL: authUser.photoURL || firestoreProfile.photoURL || null,
      role: customClaims.role || firestoreProfile.role || 'user',
      status: authUser.disabled ? 'suspended' : (firestoreProfile.status || 'active'),
      createdAt: new Date(authUser.metadata.creationTime),
      updatedAt: new Date(authUser.metadata.lastRefreshTime || authUser.metadata.creationTime),
      lastLoginAt: authUser.metadata.lastSignInTime ? new Date(authUser.metadata.lastSignInTime) : null,
      emailVerified: authUser.emailVerified,
      metadata: {
        loginCount: firestoreProfile.metadata?.loginCount || 0,
        lastIpAddress: firestoreProfile.metadata?.lastIpAddress || null,
        userAgent: firestoreProfile.metadata?.userAgent || null,
      },
    };

    return NextResponse.json({ user: userProfile });
  } catch (error: any) {
    console.error(`Error fetching user:`, error);
    
    if (error.code === 'auth/user-not-found') {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }
    
    return NextResponse.json(
      { error: `Failed to fetch user: ${error.message}` },
      { status: 500 }
    );
  }
} 