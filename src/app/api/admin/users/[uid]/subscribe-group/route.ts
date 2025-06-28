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

export async function POST(
  request: NextRequest,
  { params }: { params: { uid: string } }
): Promise<NextResponse> {
  try {
    const { uid } = params;
    const body = await request.json();
    const { groupId, action = 'subscribe' } = body; // action can be 'subscribe' or 'unsubscribe'

    if (!groupId) {
      return NextResponse.json(
        { error: 'Group ID is required' },
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

    // Get user data
    const userDoc = await firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    const userData = userDoc.data();

    // Get group data
    const groupDoc = await firestore.collection('usersMessagingGroups').doc(groupId).get();
    if (!groupDoc.exists) {
      return NextResponse.json(
        { error: 'Group not found' },
        { status: 404 }
      );
    }

    const groupData = groupDoc.data();
    if (!groupData) {
      return NextResponse.json(
        { error: 'Group data not found' },
        { status: 404 }
      );
    }

    // Get user's FCM tokens
    const tokensSnapshot = await firestore
      .collection('fcmTokens')
      .where('userId', '==', uid)
      .get();

    if (tokensSnapshot.empty) {
      return NextResponse.json(
        { error: 'No FCM tokens found for this user' },
        { status: 404 }
      );
    }

    const tokens: string[] = [];
    tokensSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.token) {
        tokens.push(data.token);
      }
    });

    if (tokens.length === 0) {
      return NextResponse.json(
        { error: 'No valid FCM tokens found for this user' },
        { status: 404 }
      );
    }

    // Subscribe or unsubscribe user tokens to/from the topic
    let result;
    if (action === 'subscribe') {
      result = await messaging.subscribeToTopic(tokens, groupData.topicId);
    } else {
      result = await messaging.unsubscribeFromTopic(tokens, groupData.topicId);
    }

    // Update user's group memberships
    const userGroupsRef = firestore.collection('userGroupMemberships').doc(uid);
    const userGroupsDoc = await userGroupsRef.get();

    let userGroups = userGroupsDoc.exists ? userGroupsDoc.data()?.groups || [] : [];

    if (action === 'subscribe') {
      // Add group if not already present
      if (!userGroups.some((g: any) => g.groupId === groupId)) {
        userGroups.push({
          groupId,
          groupName: groupData.name,
          groupNameAr: groupData.nameAr,
          topicId: groupData.topicId,
          subscribedAt: new Date(),
        });
      }
    } else {
      // Remove group
      userGroups = userGroups.filter((g: any) => g.groupId !== groupId);
    }

    // Update user's group memberships document
    await userGroupsRef.set({
      userId: uid,
      groups: userGroups,
      updatedAt: new Date(),
    }, { merge: true });

    // Update group's member count
    const currentMemberCount = groupData.memberCount || 0;
    const newMemberCount = action === 'subscribe' 
      ? currentMemberCount + 1 
      : Math.max(0, currentMemberCount - 1);

    await groupDoc.ref.update({
      memberCount: newMemberCount,
      updatedAt: new Date(),
    });

    console.log(`User ${action}d to/from group successfully:`, {
      userId: uid,
      groupId,
      topicId: groupData.topicId,
      action,
      tokensProcessed: tokens.length,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });

    return NextResponse.json({
      success: true,
      message: `User ${action}d ${action === 'subscribe' ? 'to' : 'from'} group successfully`,
      result: {
        userId: uid,
        groupId,
        groupName: groupData.name,
        topicId: groupData.topicId,
        action,
        tokensProcessed: tokens.length,
        successCount: result.successCount,
        failureCount: result.failureCount,
        newMemberCount,
      },
    });

  } catch (error: any) {
    console.error('Error managing user group subscription:', error);
    
    return NextResponse.json(
      { error: `Failed to manage user group subscription: ${error.message}` },
      { status: 500 }
    );
  }
}

// GET endpoint to check user's group memberships
export async function GET(
  request: NextRequest,
  { params }: { params: { uid: string } }
): Promise<NextResponse> {
  try {
    const { uid } = params;

    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const firestore = getFirestore();

    // Get user's group memberships
    const userGroupsDoc = await firestore.collection('userGroupMemberships').doc(uid).get();
    
    const userGroups = userGroupsDoc.exists ? userGroupsDoc.data()?.groups || [] : [];

    // Get all available groups
    const allGroupsSnapshot = await firestore.collection('usersMessagingGroups').get();
    const allGroups = allGroupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return NextResponse.json({
      success: true,
      userGroups,
      allGroups,
      userId: uid,
    });

  } catch (error: any) {
    console.error('Error fetching user group memberships:', error);
    
    return NextResponse.json(
      { error: `Failed to fetch user group memberships: ${error.message}` },
      { status: 500 }
    );
  }
} 