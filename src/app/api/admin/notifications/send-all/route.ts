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
    const { topic, notification, webpush, android, apns, data } = body;

    if (!notification?.title || !notification?.body) {
      return NextResponse.json(
        { error: 'Missing notification title or body' },
        { status: 400 }
      );
    }

    if (!topic) {
      return NextResponse.json(
        { error: 'Topic parameter is required. Please specify a group topic ID.' },
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

    const messaging = getMessaging();

    // 🚀 Send to specified group topic - no more fallback to 'allUsers'
    const message = {
      topic: topic, // Use the specific group topic from request
      notification: {
        title: notification.title,
        body: notification.body,
        ...(notification.image && { image: notification.image }),
      },
      // Add platform-specific configurations
      ...(webpush && { webpush }),
      ...(android && {
        android: {
          priority: android.priority || 'high',
          ...(android.notification && { notification: android.notification }),
          ...(android.ttl && { ttl: android.ttl }),
          ...(android.collapseKey && { collapseKey: android.collapseKey }),
        }
      }),
      ...(apns && { apns }),
      // Add custom data if provided
      ...(data && Object.keys(data).length > 0 && { data }),
    };

    // 🎯 Send to the specified group topic
    const messageId = await messaging.send(message);



    // ✅ Returns immediately - FCM handles the fan-out to group members
    return NextResponse.json({
      success: true,
      messageId,
      message: `Notification sent successfully to group: ${topic}`,
      topic,
      timestamp: new Date().toISOString(),
    });

  } catch (error: any) {
    console.error('Error sending FCM topic message:', error);
    
    return NextResponse.json(
      { error: `Failed to send notification: ${error.message}` },
      { status: 500 }
    );
  }
} 