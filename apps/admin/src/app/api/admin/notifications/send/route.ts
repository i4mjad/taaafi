import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
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
    const { token, notification, webpush, android, apns, data } = body;

    if (!token) {
      return NextResponse.json(
        { error: 'Missing messaging token' },
        { status: 400 }
      );
    }

    if (!notification?.title || !notification?.body) {
      return NextResponse.json(
        { error: 'Missing notification title or body' },
        { status: 400 }
      );
    }

    const messaging = getMessaging();

    // Construct the message payload
    const message: any = {
      token,
      notification: {
        title: notification.title,
        body: notification.body,
        ...(notification.image && { image: notification.image }),
      },
    };

    // Add platform-specific configurations
    if (webpush) {
      message.webpush = webpush;
    }

    if (android) {
      message.android = {
        priority: android.priority || 'normal',
        ...(android.notification && { notification: android.notification }),
        ...(android.ttl && { ttl: android.ttl }),
        ...(android.collapseKey && { collapseKey: android.collapseKey }),
      };
    }

    if (apns) {
      message.apns = apns;
    }

    // Add custom data if provided
    if (data && Object.keys(data).length > 0) {
      message.data = data;
    }

    // Send the message
    const response = await messaging.send(message);

    

    return NextResponse.json({
      success: true,
      messageId: response,
    });

  } catch (error: any) {
    console.error('Error sending FCM message:', error);

    // Handle specific FCM errors
    if (error.code === 'messaging/invalid-registration-token') {
      return NextResponse.json(
        { error: 'Invalid or expired messaging token' },
        { status: 400 }
      );
    }

    if (error.code === 'messaging/registration-token-not-registered') {
      return NextResponse.json(
        { error: 'Messaging token not registered' },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { error: `Failed to send notification: ${error.message}` },
      { status: 500 }
    );
  }
} 