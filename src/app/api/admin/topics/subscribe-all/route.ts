import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
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

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json();
    const { topic } = body;

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
    const firestore = getFirestore();

    // Get all FCM tokens from Firestore
    // Assuming you store tokens in a 'fcmTokens' collection
    const tokensSnapshot = await firestore.collection('fcmTokens').get();
    
    if (tokensSnapshot.empty) {
      return NextResponse.json({
        success: true,
        message: 'No tokens found to subscribe',
        subscribedCount: 0,
        topic,
      });
    }

    const tokens: string[] = [];
    tokensSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.token) {
        tokens.push(data.token);
      }
    });

    if (tokens.length === 0) {
      return NextResponse.json({
        success: true,
        message: 'No valid tokens found to subscribe',
        subscribedCount: 0,
        topic,
      });
    }

    // Subscribe tokens to topic in batches (FCM allows up to 1000 tokens per batch)
    const batchSize = 1000;
    let subscribedCount = 0;
    const errors: any[] = [];

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      
      try {
        const response = await messaging.subscribeToTopic(batch, topic);
        subscribedCount += response.successCount;
        
        if (response.failureCount > 0) {
          response.errors.forEach(error => errors.push(error));
        }
      } catch (error) {
        console.error(`Error subscribing batch ${i / batchSize + 1}:`, error);
        errors.push(error);
      }
    }

    console.log(`Successfully subscribed ${subscribedCount}/${tokens.length} tokens to group topic: ${topic}`);

    return NextResponse.json({
      success: true,
      message: `Successfully subscribed ${subscribedCount} tokens to group: ${topic}`,
      subscribedCount,
      totalTokens: tokens.length,
      topic,
      errors: errors.length > 0 ? errors : undefined,
      timestamp: new Date().toISOString(),
    });

  } catch (error: any) {
    console.error('Error subscribing to topic:', error);
    
    return NextResponse.json(
      { error: `Failed to subscribe to topic: ${error.message}` },
      { status: 500 }
    );
  }
}

// GET endpoint to check subscription status
export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const topic = searchParams.get('topic');

    if (!topic) {
      return NextResponse.json(
        { error: 'Topic parameter is required.' },
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

    // Get count of FCM tokens
    const tokensSnapshot = await firestore.collection('fcmTokens').get();
    const totalTokens = tokensSnapshot.size;

    return NextResponse.json({
      topic,
      totalTokens,
      message: `Group topic: ${topic} has ${totalTokens} potential subscribers`,
      timestamp: new Date().toISOString(),
    });

  } catch (error: any) {
    console.error('Error checking topic status:', error);
    
    return NextResponse.json(
      { error: `Failed to check topic status: ${error.message}` },
      { status: 500 }
    );
  }
} 