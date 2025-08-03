import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

// Initialize Firebase Admin SDK
if (!getApps().length) {
  const serviceAccount = {
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
    privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
  };

  if (!serviceAccount.projectId || !serviceAccount.privateKey || !serviceAccount.clientEmail) {
    console.warn('Firebase Admin SDK credentials not found in environment variables. Please set FIREBASE_ADMIN_PROJECT_ID, FIREBASE_ADMIN_PRIVATE_KEY, and FIREBASE_ADMIN_CLIENT_EMAIL');
  } else {
    initializeApp({
      credential: cert(serviceAccount),
    });
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { uid: string } }
) {
  try {
    const userId = params.uid;

    if (!userId) {
      return NextResponse.json(
        { error: 'User ID is required' },
        { status: 400 }
      );
    }

    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const auth = getAuth();

    // Only handle Firebase Auth deletion here - this requires admin SDK
    // All Firestore operations should be handled by React Firebase hooks on the frontend
    await auth.deleteUser(userId);

    return NextResponse.json({
      success: true,
      message: 'Firebase Auth user deleted successfully'
    });

  } catch (error: any) {
    console.error('Error deleting Firebase Auth user:', error);
    
    // Handle specific Firebase Auth errors
    if (error.code === 'auth/user-not-found') {
      return NextResponse.json(
        { error: 'User not found in Firebase Auth' },
        { status: 404 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to delete Firebase Auth user', details: error.message },
      { status: 500 }
    );
  }
}

