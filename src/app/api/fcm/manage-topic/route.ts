import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

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

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json();
    const { userId, topicId, action } = body;

    // Validate inputs
    if (!userId || !topicId || !action) {
      return NextResponse.json(
        { error: 'userId, topicId, and action are required' },
        { status: 400 }
      );
    }

    if (!['subscribe', 'unsubscribe'].includes(action)) {
      return NextResponse.json(
        { error: 'Action must be either "subscribe" or "unsubscribe"' },
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

    const firestore = getFirestore();
    const messaging = getMessaging();

    // Get user's messaging token from their document
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    const userData = userDoc.data();
    const messagingToken = userData?.messagingToken;

    if (!messagingToken || typeof messagingToken !== 'string' || !messagingToken.trim()) {
      return NextResponse.json(
        { error: 'User has no valid messaging token' },
        { status: 404 }
      );
    }

    // Subscribe or unsubscribe user token to/from the topic
    let result;
    try {
      if (action === 'subscribe') {
        result = await messaging.subscribeToTopic([messagingToken], topicId);
      } else {
        result = await messaging.unsubscribeFromTopic([messagingToken], topicId);
      }
    } catch (messagingError: any) {
      console.error('FCM messaging error:', messagingError);
      return NextResponse.json(
        { error: `FCM ${action} failed: ${messagingError.message}` },
        { status: 500 }
      );
    }

    // Check if operation was successful
    if (result.failureCount > 0) {
      console.warn(`FCM ${action} failed for user ${userId}:`, result.errors);
      
      return NextResponse.json(
        { error: `FCM token failed to ${action}. Token may be invalid or expired.` },
        { status: 500 }
      );
    }

    console.log(`FCM ${action} completed successfully:`, {
      userId,
      topicId,
      action,
      successCount: result.successCount,
    });

    return NextResponse.json({
      success: true,
      message: `Successfully ${action}d user token ${action === 'subscribe' ? 'to' : 'from'} topic: ${topicId}`,
      result: {
        userId,
        topicId,
        action,
        successCount: result.successCount,
        failureCount: result.failureCount,
      },
    });

  } catch (error: any) {
    console.error('Error managing FCM topic subscription:', error);
    
    return NextResponse.json(
      { error: `Failed to manage FCM topic subscription: ${error.message}` },
      { status: 500 }
    );
  }
} 