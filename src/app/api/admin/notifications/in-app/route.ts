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

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json();
    const { topic, title, body: messageBody, type, actionText, actionUrl, persistent } = body;

    // Validate required fields
    if (!title?.trim()) {
      return NextResponse.json(
        { error: 'Notification title is required' },
        { status: 400 }
      );
    }

    if (!messageBody?.trim()) {
      return NextResponse.json(
        { error: 'Notification message is required' },
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

    const firestore = getFirestore();

    // Create in-app notification document structure
    const notificationData = {
      title: title.trim(),
      body: messageBody.trim(),
      type: type || 'info',
      targetTopic: topic,
      ...(actionText && { actionText: actionText.trim() }),
      ...(actionUrl && { actionUrl: actionUrl.trim() }),
      persistent: Boolean(persistent),
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: true,
      sentToGroups: [topic] // Track which groups this was sent to
    };

    // Store the in-app notification in Firestore
    const notificationRef = await firestore
      .collection('inAppNotifications')
      .add(notificationData);

    // Get the group information to provide feedback
    let groupInfo = { name: topic, memberCount: 0 };
    try {
      const groupDoc = await firestore
        .collection('groups')
        .where('topicId', '==', topic)
        .limit(1)
        .get();

      if (!groupDoc.empty) {
        const group = groupDoc.docs[0].data();
        groupInfo = {
          name: group.name || topic,
          memberCount: group.memberCount || 0
        };
      }
    } catch (error) {
      console.warn('Could not fetch group info:', error);
    }

    

    return NextResponse.json({
      success: true,
      notificationId: notificationRef.id,
      message: `In-app notification sent successfully to group: ${groupInfo.name}`,
      topic,
      groupInfo,
      timestamp: new Date().toISOString(),
    });

  } catch (error: any) {
    console.error('Error creating in-app notification:', error);
    
    return NextResponse.json(
      { error: `Failed to send in-app notification: ${error.message}` },
      { status: 500 }
    );
  }
}

// GET endpoint to retrieve in-app notifications for a specific topic/group
export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    const { searchParams } = new URL(request.url);
    const topic = searchParams.get('topic');
    const userId = searchParams.get('userId');
    const limit = parseInt(searchParams.get('limit') || '50');

    if (!topic && !userId) {
      return NextResponse.json(
        { error: 'Either topic or userId parameter is required.' },
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

    if (topic) {
      // Get notifications for a specific group topic
      const query = firestore.collection('inAppNotifications')
        .where('targetTopic', '==', topic)
        .where('isActive', '==', true)
        .orderBy('createdAt', 'desc')
        .limit(limit);
      
      const snapshot = await query.get();
      const notifications = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
        updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt,
      }));

      return NextResponse.json({
        success: true,
        notifications,
        count: notifications.length,
        topic,
        timestamp: new Date().toISOString(),
      });
    } else if (userId) {
      // Get notifications for a specific user (you would need to implement user-group relationship logic here)
      // This is a placeholder - you'll need to implement based on your user-group data structure
      return NextResponse.json(
        { error: 'User-specific notifications not yet implemented. Use topic parameter instead.' },
        { status: 501 }
      );
    }

    // This should not be reached due to the validation above
    return NextResponse.json(
      { error: 'Invalid request parameters.' },
      { status: 400 }
    );

  } catch (error: any) {
    console.error('Error fetching in-app notifications:', error);
    
    return NextResponse.json(
      { error: `Failed to fetch in-app notifications: ${error.message}` },
      { status: 500 }
    );
  }
} 