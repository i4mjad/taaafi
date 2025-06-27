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

export async function POST(
  request: NextRequest,
  { params }: { params: { uid: string } }
) {
  try {
    const { uid } = params;
    const { banned } = await request.json();

    const auth = getAuth();
    const firestore = getFirestore();

    // Update Firebase Auth user disabled status
    await auth.updateUser(uid, {
      disabled: banned
    });

    // Update user status in Firestore (if document exists)
    try {
      const userDoc = firestore.collection('users').doc(uid);
      const userSnapshot = await userDoc.get();
      
      if (userSnapshot.exists) {
        await userDoc.update({
          status: banned ? 'suspended' : 'active',
          updatedAt: new Date()
        });
      }
    } catch (firestoreError) {
      console.warn(`Could not update Firestore document for user ${uid}:`, firestoreError);
    }
    
    return NextResponse.json({ 
      success: true, 
      message: `User ${banned ? 'banned' : 'unbanned'} successfully`,
      uid,
      banned 
    });
  } catch (error: any) {
    console.error('Error updating user ban status:', error);
    return NextResponse.json(
      { error: `Failed to update user status: ${error.message}` },
      { status: 500 }
    );
  }
} 